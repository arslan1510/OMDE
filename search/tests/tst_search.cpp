#include <QtTest/QtTest>
#include <QScopedPointer>
#include <QSignalSpy>
#include <QVariant>
#include <QVariantMap>
#include <QQmlComponent>
#include <QQmlEngine>

#include "searchindex.hpp"

namespace {

QVariantMap app(const QString &name)
{
    QVariantMap item;
    item.insert(QStringLiteral("name"), name);
    return item;
}

void addAll(SearchIndex &index, const QStringList &names)
{
    for (const QString &name : names)
        index.add(app(name), name, {}, name);
}

QStringList rankNames(SearchIndex &index, const QString &query, int limit,
                      const QVariantMap &boosts = {})
{
    const QVariantList items = index.rank(query, limit, boosts);
    QStringList names;
    names.reserve(items.size());
    for (const QVariant &item : items)
        names.append(item.toMap().value(QStringLiteral("name")).toString());
    return names;
}

QString first(SearchIndex &index, const QString &query, const QVariantMap &boosts = {})
{
    const QStringList names = rankNames(index, query, index.count(), boosts);
    return names.isEmpty() ? QString() : names.first();
}

QVariantMap usage(const QString &key, int score)
{
    QVariantMap scores;
    scores.insert(key, score);
    return scores;
}

}

class SearchTest : public QObject
{
    Q_OBJECT

private slots:
    void wordsMustAllMatch();
    void subsequence();
    void wordInitials();
    void plainPrefix();
    void smartCaseFindsUppercaseQuery();
    void caseFallbackFindsLowercaseText();
    void exactCaseOutranksFallback();
    void longInputMatches();
    void prefixOperator();
    void substringOperator();

    void runBeatsGaps();
    void boundaryBeatsMiddle();
    void runBeatsSeparator();
    void firstCharacterBeatsLaterBoundary();

    void usageOrdersEmptyQuery();
    void usageBoostsMatches();
    void withoutUsageUsesMatchOrder();

    void emptyQueryKeepsInsertionOrder();
    void limitCapsResults();
    void clearDropsEntries();
    void countTracksEntries();
    void countSignalOnAddAndClear();
    void zeroOrNegativeLimitReturnsNothing();
    void whitespaceQueryKeepsInsertionOrder();
    void operatorsIgnoreCase();
    void boostIgnoresMissingKeys();
    void rankKeysRespectBoost();
    void statefulIndexCanBeReused();
    void wordsMatchAfterName();
    void unicodeCaseFold();
    void rankKeysUseEntryKeys();
    void qmlIndexRoundTripsItems();
};

void SearchTest::wordsMustAllMatch()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Firefox"), QStringLiteral("Firefox Browser"),
                   QStringLiteral("Files"), QStringLiteral("Fish")});
    QCOMPARE(first(index, QStringLiteral("fi br")), QStringLiteral("Firefox Browser"));
}

void SearchTest::subsequence()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Firefox"), QStringLiteral("Files")});
    QCOMPARE(first(index, QStringLiteral("ffx")), QStringLiteral("Firefox"));
}

void SearchTest::wordInitials()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Visual Studio Code"), QStringLiteral("Vim")});
    QCOMPARE(first(index, QStringLiteral("vsc")), QStringLiteral("Visual Studio Code"));
}

void SearchTest::plainPrefix()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Ghostty"), QStringLiteral("GIMP")});
    QCOMPARE(first(index, QStringLiteral("gh")), QStringLiteral("Ghostty"));
}

void SearchTest::smartCaseFindsUppercaseQuery()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Fish"), QStringLiteral("Firefox")});
    QCOMPARE(first(index, QStringLiteral("Fi")), QStringLiteral("Fish"));
}

void SearchTest::caseFallbackFindsLowercaseText()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Firefox")});
    QCOMPARE(first(index, QStringLiteral("FF")), QStringLiteral("Firefox"));
}

void SearchTest::exactCaseOutranksFallback()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("FastFetch"), QStringLiteral("Firefox")});
    QCOMPARE(first(index, QStringLiteral("FF")), QStringLiteral("FastFetch"));
}

void SearchTest::longInputMatches()
{
    SearchIndex index;
    const QString longName = QString(2000, QLatin1Char('x')) + QStringLiteral("Firefox");
    index.add(app(longName), longName, {}, longName);
    QCOMPARE(first(index, QStringLiteral("fox")), longName);
}

void SearchTest::prefixOperator()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Fish"), QStringLiteral("Firefox")});
    QCOMPARE(first(index, QStringLiteral("^fi")), QStringLiteral("Fish"));
}

void SearchTest::substringOperator()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Firefox"), QStringLiteral("Firefox Browser")});
    QCOMPARE(first(index, QStringLiteral("'fox")), QStringLiteral("Firefox"));
}

void SearchTest::runBeatsGaps()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("abc"), QStringLiteral("axbxc"),
                   QStringLiteral("a_b_c"), QStringLiteral("xxabc")});
    QCOMPARE(first(index, QStringLiteral("abc")), QStringLiteral("abc"));
}

void SearchTest::boundaryBeatsMiddle()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("xfbc"), QStringLiteral("foo-bar"),
                   QStringLiteral("foobar")});
    QCOMPARE(first(index, QStringLiteral("fb")), QStringLiteral("foo-bar"));
}

void SearchTest::runBeatsSeparator()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("foobar"), QStringLiteral("foo-bar")});
    QCOMPARE(first(index, QStringLiteral("foob")), QStringLiteral("foobar"));
}

void SearchTest::firstCharacterBeatsLaterBoundary()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("to-go"), QStringLiteral("ongoing")});
    QCOMPARE(first(index, QStringLiteral("og")), QStringLiteral("ongoing"));
}

void SearchTest::usageOrdersEmptyQuery()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Firefox"), QStringLiteral("Zed"), QStringLiteral("Helix")});

    QVariantMap boosts = usage(QStringLiteral("Zed"), 44);
    boosts.insert(QStringLiteral("Helix"), 20);
    QCOMPARE(rankNames(index, QString(), 2, boosts),
             (QStringList{QStringLiteral("Zed"), QStringLiteral("Helix")}));
}

void SearchTest::usageBoostsMatches()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Firefox"), QStringLiteral("Zed"), QStringLiteral("Helix"),
                   QStringLiteral("Code")});

    QVariantMap boosts = usage(QStringLiteral("Zed"), 44);
    boosts.insert(QStringLiteral("Helix"), 20);
    QCOMPARE(rankNames(index, QStringLiteral("e"), 2, boosts),
             (QStringList{QStringLiteral("Zed"), QStringLiteral("Helix")}));
}

void SearchTest::withoutUsageUsesMatchOrder()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Firefox"), QStringLiteral("Zed"), QStringLiteral("Helix"),
                   QStringLiteral("Code")});
    QCOMPARE(rankNames(index, QStringLiteral("e"), 2),
             (QStringList{QStringLiteral("Zed"), QStringLiteral("Code")}));
}

void SearchTest::emptyQueryKeepsInsertionOrder()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("C"), QStringLiteral("A"), QStringLiteral("B")});
    QCOMPARE(rankNames(index, QString(), 3),
             (QStringList{QStringLiteral("C"), QStringLiteral("A"), QStringLiteral("B")}));
}

void SearchTest::limitCapsResults()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("A"), QStringLiteral("B"), QStringLiteral("C")});
    QCOMPARE(index.rank(QString(), 2, {}).size(), 2);
}

void SearchTest::clearDropsEntries()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("A")});
    index.clear();
    QCOMPARE(index.count(), 0);
    QVERIFY(index.rank(QString(), 10, {}).isEmpty());
}

void SearchTest::countTracksEntries()
{
    SearchIndex index;
    QCOMPARE(index.count(), 0);
    addAll(index, {QStringLiteral("A"), QStringLiteral("B")});
    QCOMPARE(index.count(), 2);
    index.clear();
    QCOMPARE(index.count(), 0);
}

void SearchTest::countSignalOnAddAndClear()
{
    SearchIndex index;
    QSignalSpy spy(&index, &SearchIndex::countChanged);

    addAll(index, {QStringLiteral("A")});
    QCOMPARE(spy.count(), 1);

    index.clear();
    QCOMPARE(spy.count(), 2);

    index.clear();
    QCOMPARE(spy.count(), 2);
}

void SearchTest::zeroOrNegativeLimitReturnsNothing()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("A")});
    QVERIFY(index.rank(QStringLiteral("a"), 0, {}).isEmpty());
    QVERIFY(index.rank(QStringLiteral("a"), -1, {}).isEmpty());
}

void SearchTest::whitespaceQueryKeepsInsertionOrder()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("C"), QStringLiteral("A"), QStringLiteral("B")});
    QCOMPARE(rankNames(index, QStringLiteral("   "), 3),
             (QStringList{QStringLiteral("C"), QStringLiteral("A"), QStringLiteral("B")}));
}

void SearchTest::operatorsIgnoreCase()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("Fish"), QStringLiteral("GIMP")});
    QCOMPARE(first(index, QStringLiteral("^FI")), QStringLiteral("Fish"));
    QCOMPARE(first(index, QStringLiteral("'IM")), QStringLiteral("GIMP"));
}

void SearchTest::boostIgnoresMissingKeys()
{
    SearchIndex index;
    addAll(index, {QStringLiteral("C"), QStringLiteral("A"), QStringLiteral("B")});
    QCOMPARE(rankNames(index, QString(), 3, usage(QStringLiteral("missing"), 1000)),
             (QStringList{QStringLiteral("C"), QStringLiteral("A"), QStringLiteral("B")}));
}

void SearchTest::rankKeysRespectBoost()
{
    SearchIndex index;
    index.add(app(QStringLiteral("Firefox")), QStringLiteral("Firefox"), {},
              QStringLiteral("firefox"));
    index.add(app(QStringLiteral("Files")), QStringLiteral("Files"), {},
              QStringLiteral("files"));
    QCOMPARE(index.rankKeys(QStringLiteral("fi"), 2, usage(QStringLiteral("files"), 1000)),
             (QStringList{QStringLiteral("files"), QStringLiteral("firefox")}));
}

void SearchTest::statefulIndexCanBeReused()
{
    SearchIndex index;
    index.add(app(QStringLiteral("Apple")), QStringLiteral("Apple"), {}, QStringLiteral("apple"));
    QCOMPARE(first(index, QStringLiteral("app")), QStringLiteral("Apple"));

    index.clear();
    index.add(app(QStringLiteral("Banana")), QStringLiteral("Banana"), {}, QStringLiteral("banana"));
    QVERIFY(first(index, QStringLiteral("app")).isEmpty());
    QCOMPARE(first(index, QStringLiteral("ban")), QStringLiteral("Banana"));
}

void SearchTest::wordsMatchAfterName()
{
    SearchIndex index;
    index.add(app(QStringLiteral("Firefox")), QStringLiteral("Firefox"),
              {QStringLiteral("Browser")}, QStringLiteral("firefox"));
    QCOMPARE(first(index, QStringLiteral("browser")), QStringLiteral("Firefox"));
}

void SearchTest::unicodeCaseFold()
{
    SearchIndex index;
    index.add(app(QStringLiteral("Äpfel")), QStringLiteral("Äpfel"), {},
              QStringLiteral("äpfel"));
    QCOMPARE(first(index, QStringLiteral("äpfel")), QStringLiteral("Äpfel"));
}

void SearchTest::rankKeysUseEntryKeys()
{
    SearchIndex index;
    index.add(app(QStringLiteral("Firefox")), QStringLiteral("Firefox"),
              {QStringLiteral("Browser")}, QStringLiteral("firefox"));
    QCOMPARE(index.rankKeys(QStringLiteral("brow"), 1, {}),
             (QStringList{QStringLiteral("firefox")}));
}

void SearchTest::qmlIndexRoundTripsItems()
{
    QQmlEngine engine;
    engine.addImportPath(QStringLiteral(OMDE_SEARCH_IMPORT_PATH));
    engine.addImportPath(QStringLiteral(QT_QML_IMPORT_DIR));

    QQmlComponent component(&engine);
    component.setData(R"(
        import QtQml
        import OMDE.Search

        QtObject {
            id: root
            property SearchIndex index: SearchIndex {}
            property QtObject entry: QtObject {
                property string name: "Firefox"
                property string id: "firefox"
            }

            function run() {
                index.add(entry, entry.name, ["Browser"], entry.id);
                const keys = index.rankKeys("brow", 5, {});
                const results = index.rank("brow", 5, {});
                return keys[0] === "firefox" && results[0].name === "Firefox" ? "ok" : "";
            }
        }
    )", QUrl(QStringLiteral("qrc:/tst_qml.qml")));

    if (!component.isReady())
        QFAIL(qPrintable(component.errorString()));

    QScopedPointer<QObject> object(component.create());
    QVERIFY(object);

    QVariant result;
    QVERIFY(QMetaObject::invokeMethod(object.data(), "run",
                                      Q_RETURN_ARG(QVariant, result)));
    QCOMPARE(result.toString(), QStringLiteral("ok"));
}

QTEST_GUILESS_MAIN(SearchTest)

#include "tst_search.moc"
