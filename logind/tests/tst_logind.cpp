#include <QtTest/QtTest>
#include <QDBusConnection>
#include <QSignalSpy>
#include <QScopedPointer>
#include <QQmlComponent>
#include <QQmlEngine>

#include "logind.hpp"

namespace {

QDBusConnection offlineBus()
{
    return QDBusConnection(QStringLiteral("omde-logind-test"));
}

}

class LogindTest : public QObject
{
    Q_OBJECT

private slots:
    void propertiesStartDisabled();
    void inhibitSleepSignalOnlyOnChange();
    void lockedHintSignalOnlyOnChange();
    void metaPropertiesAreWritable();
    void qmlSingletonExposesProperties();
};

void LogindTest::propertiesStartDisabled()
{
    Logind logind(offlineBus());
    QCOMPARE(logind.inhibitSleep(), false);
    QCOMPARE(logind.lockedHint(), false);
}

void LogindTest::inhibitSleepSignalOnlyOnChange()
{
    Logind logind(offlineBus());
    QSignalSpy spy(&logind, &Logind::inhibitSleepChanged);

    logind.setInhibitSleep(false);
    QCOMPARE(spy.count(), 0);

    logind.setInhibitSleep(true);
    QCOMPARE(spy.count(), 1);
    QCOMPARE(logind.inhibitSleep(), true);

    logind.setInhibitSleep(true);
    QCOMPARE(spy.count(), 1);

    logind.setInhibitSleep(false);
    QCOMPARE(spy.count(), 2);
    QCOMPARE(logind.inhibitSleep(), false);
}

void LogindTest::lockedHintSignalOnlyOnChange()
{
    Logind logind(offlineBus());
    QSignalSpy spy(&logind, &Logind::lockedHintChanged);

    logind.setLockedHint(false);
    QCOMPARE(spy.count(), 0);

    logind.setLockedHint(true);
    QCOMPARE(spy.count(), 1);
    QCOMPARE(logind.lockedHint(), true);

    logind.setLockedHint(true);
    QCOMPARE(spy.count(), 1);

    logind.setLockedHint(false);
    QCOMPARE(spy.count(), 2);
    QCOMPARE(logind.lockedHint(), false);
}

void LogindTest::metaPropertiesAreWritable()
{
    Logind logind(offlineBus());

    QVERIFY(logind.setProperty("inhibitSleep", true));
    QCOMPARE(logind.property("inhibitSleep").toBool(), true);

    QVERIFY(logind.setProperty("lockedHint", true));
    QCOMPARE(logind.property("lockedHint").toBool(), true);
}

void LogindTest::qmlSingletonExposesProperties()
{
    QQmlEngine engine;
    engine.addImportPath(QStringLiteral(OMDE_LOGIND_IMPORT_PATH));
    engine.addImportPath(QStringLiteral(QT_QML_IMPORT_DIR));

    QQmlComponent component(&engine);
    component.setData(R"(
        import QtQml
        import OMDE.Logind

        QtObject {
            function run() {
                return typeof Logind.inhibitSleep === "boolean"
                    && typeof Logind.lockedHint === "boolean" ? "ok" : "";
            }
        }
    )", QUrl(QStringLiteral("qrc:/tst_logind.qml")));

    if (!component.isReady())
        QFAIL(qPrintable(component.errorString()));

    QScopedPointer<QObject> object(component.create());
    QVERIFY(object);

    QVariant result;
    QVERIFY(QMetaObject::invokeMethod(object.data(), "run",
                                      Q_RETURN_ARG(QVariant, result)));
    QCOMPARE(result.toString(), QStringLiteral("ok"));
}

QTEST_GUILESS_MAIN(LogindTest)

#include "tst_logind.moc"
