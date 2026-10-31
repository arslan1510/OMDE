#include "logind.hpp"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDebug>

namespace {

const QString SERVICE = QStringLiteral("org.freedesktop.login1");
const QString MANAGER_PATH = QStringLiteral("/org/freedesktop/login1");
const QString MANAGER = QStringLiteral("org.freedesktop.login1.Manager");
const QString SESSION = QStringLiteral("org.freedesktop.login1.Session");

QDBusMessage managerCall(const QString& method) {
	return QDBusMessage::createMethodCall(SERVICE, MANAGER_PATH, MANAGER, method);
}

}

Logind::Logind(QObject* parent): Logind(QDBusConnection::systemBus(), parent) {
}

Logind::Logind(const QDBusConnection& bus, QObject* parent): QObject(parent), mBus(bus) {
	this->mBus.connect(SERVICE, MANAGER_PATH, MANAGER, "PrepareForSleep", this, SIGNAL(prepareForSleep(bool)));

	this->mInhibitRetry.setSingleShot(true);
	this->mInhibitRetry.setInterval(1000);
	QObject::connect(&this->mInhibitRetry, &QTimer::timeout, this, &Logind::acquireInhibitor);
	this->mSessionRetry.setSingleShot(true);
	this->mSessionRetry.setInterval(1000);
	QObject::connect(&this->mSessionRetry, &QTimer::timeout, this, &Logind::discoverSession);
	this->discoverSession();
}

void Logind::discoverSession() {
	auto call = managerCall("GetSession");
	call << QStringLiteral("auto");
	auto* watcher = new QDBusPendingCallWatcher(this->mBus.asyncCall(call), this);
	QObject::connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher* w) {
		const QDBusPendingReply<QDBusObjectPath> reply = *w;
		w->deleteLater();
		if (reply.isError() || reply.value().path().isEmpty()) {
			qWarning().noquote() << "logind GetSession(auto) failed:"
			                    << (reply.isError() ? reply.error().name() + ": " + reply.error().message()
			                                        : QStringLiteral("empty session object path"))
			                    << "; Lock/Unlock are not subscribed; retrying in"
			                    << this->mSessionRetry.interval() << "ms";
			this->mSessionRetry.start();
			return;
		}

		const auto path = reply.value().path();
		const bool lockConnected = this->mBus.connect(SERVICE, path, SESSION, "Lock", this, SIGNAL(lockRequested()));
		const bool unlockConnected = this->mBus.connect(SERVICE, path, SESSION, "Unlock", this, SIGNAL(unlockRequested()));
		if (!lockConnected || !unlockConnected) {
			this->mBus.disconnect(SERVICE, path, SESSION, "Lock", this, SIGNAL(lockRequested()));
			this->mBus.disconnect(SERVICE, path, SESSION, "Unlock", this, SIGNAL(unlockRequested()));
			qWarning().noquote() << "logind Lock/Unlock subscription failed for" << path
			                    << "; retrying GetSession(auto) in" << this->mSessionRetry.interval() << "ms";
			this->mSessionRetry.start();
			return;
		}

		this->mSessionPath = path;
		if (this->mLockedHint) this->sendLockedHint();
	});
}

void Logind::setInhibitSleep(bool inhibit) {
	const bool changed = inhibit != this->mInhibitSleep;
	if (changed) {
		this->mInhibitSleep = inhibit;
		++this->mInhibitGeneration;
	}

	if (!inhibit) {
		this->mInhibitRetry.stop();
		this->mInhibitCall = nullptr;
		this->mInhibitor = QDBusUnixFileDescriptor();
	} else {
		this->acquireInhibitor();
	}

	if (changed) emit this->inhibitSleepChanged();
}

void Logind::acquireInhibitor() {
	if (!this->mInhibitSleep || this->mInhibitor.isValid() || this->mInhibitCall) return;
	this->mInhibitRetry.stop();

	auto call = managerCall("Inhibit");
	call << QStringLiteral("sleep") << QStringLiteral("omde")
	     << QStringLiteral("Lock the screen before sleep") << QStringLiteral("delay");

	const auto generation = this->mInhibitGeneration;
	auto* watcher = new QDBusPendingCallWatcher(this->mBus.asyncCall(call), this);
	this->mInhibitCall = watcher;
	QObject::connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, generation](QDBusPendingCallWatcher* w) {
		const QDBusPendingReply<QDBusUnixFileDescriptor> reply = *w;
		w->deleteLater();
		if (!this->mInhibitSleep || generation != this->mInhibitGeneration || this->mInhibitCall != w) return;
		this->mInhibitCall = nullptr;

		if (reply.isError() || !reply.value().isValid()) {
			qWarning().noquote() << "logind Inhibit(sleep, delay) failed:"
			                    << (reply.isError() ? reply.error().name() + ": " + reply.error().message()
			                                        : QStringLiteral("invalid inhibitor file descriptor"))
			                    << "; sleep is not inhibited; retrying in" << this->mInhibitRetry.interval()
			                    << "ms while inhibitSleep is requested";
			this->mInhibitRetry.start();
			return;
		}

		this->mInhibitor = reply.value();
	});
}

void Logind::setLockedHint(bool locked) {
	if (locked == this->mLockedHint) return;
	this->mLockedHint = locked;
	emit this->lockedHintChanged();

	if (!this->mSessionPath.isEmpty()) this->sendLockedHint();
}

void Logind::sendLockedHint() {
	auto call = QDBusMessage::createMethodCall(SERVICE, this->mSessionPath, SESSION, "SetLockedHint");
	call << this->mLockedHint;
	this->mBus.send(call);
}

void Logind::suspend() { this->callManager("Suspend"); }
void Logind::reboot() { this->callManager("Reboot"); }
void Logind::powerOff() { this->callManager("PowerOff"); }

void Logind::callManager(const QString& method) {
	auto call = managerCall(method);
	call << true; // interactive: polkit may prompt
	this->mBus.send(call);
}
