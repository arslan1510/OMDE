#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QVariantList>
#include <QVariantMap>
#include <QVector>
#include <QtQml/qqmlregistration.h>

#include <cstddef>
#include <memory>

class SearchIndex: public QObject {
	Q_OBJECT;
	QML_ELEMENT;

	Q_PROPERTY(int count READ count NOTIFY countChanged);

public:
	explicit SearchIndex(QObject* parent = nullptr);
	~SearchIndex() override;

	[[nodiscard]] int count() const;

	Q_INVOKABLE void clear();
	Q_INVOKABLE void add(const QVariant& item, const QString& name,
		const QStringList& words, const QString& key);
	Q_INVOKABLE QVariantList rank(const QString& query, int limit,
		const QVariantMap& boosts) const;
	Q_INVOKABLE QStringList rankKeys(const QString& query, int limit,
		const QVariantMap& boosts) const;

signals:
	void countChanged();

private:
	struct Private;
	QVector<size_t> rankIndices(const QString& query, int limit,
		const QVariantMap& boosts) const;
	std::unique_ptr<Private> mData;
};
