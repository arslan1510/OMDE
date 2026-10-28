#pragma once

#include <QDBusConnection>
#include <QDBusUnixFileDescriptor>
#include <QObject>
#include <QString>
#include <QtQml/qqmlregistration.h>

class Logind: public QObject {
	Q_OBJECT;
	QML_ELEMENT;
	QML_SINGLETON;

	Q_PROPERTY(bool inhibitSleep READ inhibitSleep WRITE setInhibitSleep NOTIFY inhibitSleepChanged);
	Q_PROPERTY(bool lockedHint READ lockedHint WRITE setLockedHint NOTIFY lockedHintChanged);

public:
	explicit Logind(QObject* parent = nullptr);
	Logind(const QDBusConnection& bus, QObject* parent = nullptr);

	[[nodiscard]] bool inhibitSleep() const { return this->mInhibitSleep; }
	void setInhibitSleep(bool inhibit);

	[[nodiscard]] bool lockedHint() const { return this->mLockedHint; }
	void setLockedHint(bool locked);

	Q_INVOKABLE void suspend();
	Q_INVOKABLE void reboot();
	Q_INVOKABLE void powerOff();

signals:
	void inhibitSleepChanged();
	void lockedHintChanged();
	void prepareForSleep(bool start);
	void lockRequested();
	void unlockRequested();

private:
	void callManager(const QString& method);

	bool mInhibitSleep = false;
	bool mLockedHint = false;
	QString mSessionPath;
	QDBusUnixFileDescriptor mInhibitor;
	QDBusConnection mBus;
};
