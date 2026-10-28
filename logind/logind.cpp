#include "logind.hpp"

#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusObjectPath>
#include <QDBusPendingCallWatcher>
#include <QDBusPendingReply>
#include <QDBusReply>

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

// QML uses the system bus; tests inject an offline connection.
Logind::Logind(const QDBusConnection& bus, QObject* parent): QObject(parent), mBus(bus) {
	this->mBus.connect(SERVICE, MANAGER_PATH, MANAGER, "PrepareForSleep", this, SIGNAL(prepareForSleep(bool)));

	// "auto" is the session this process belongs to.
	auto call = managerCall("GetSession");
	call << QStringLiteral("auto");
	this->mSessionPath = QDBusReply<QDBusObjectPath>(this->mBus.call(call)).value().path();
	this->mBus.connect(SERVICE, this->mSessionPath, SESSION, "Lock", this, SIGNAL(lockRequested()));
	this->mBus.connect(SERVICE, this->mSessionPath, SESSION, "Unlock", this, SIGNAL(unlockRequested()));
}

void Logind::setInhibitSleep(bool inhibit) {
	if (inhibit == this->mInhibitSleep) return;
	this->mInhibitSleep = inhibit;
	emit this->inhibitSleepChanged();

	if (!inhibit) {
		// Closing the last reference releases the inhibitor.
		this->mInhibitor = QDBusUnixFileDescriptor();
		return;
	}

	// A delay inhibitor holds sleep until the lock screen is up.
	auto call = managerCall("Inhibit");
	call << QStringLiteral("sleep") << QStringLiteral("omde")
	     << QStringLiteral("Lock the screen before sleep") << QStringLiteral("delay");

	auto* watcher = new QDBusPendingCallWatcher(this->mBus.asyncCall(call), this);
	QObject::connect(watcher, &QDBusPendingCallWatcher::finished, this, [this](QDBusPendingCallWatcher* w) {
		const QDBusPendingReply<QDBusUnixFileDescriptor> reply = *w;
		w->deleteLater();
		// Ignore a late reply once inhibition is off.
		if (this->mInhibitSleep) this->mInhibitor = reply.value();
	});
}

void Logind::setLockedHint(bool locked) {
	if (locked == this->mLockedHint) return;
	this->mLockedHint = locked;
	emit this->lockedHintChanged();

	// Tell logind the session is locked so other services see it.
	auto call = QDBusMessage::createMethodCall(SERVICE, this->mSessionPath, SESSION, "SetLockedHint");
	call << locked;
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
