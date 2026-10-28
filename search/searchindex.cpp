#include "searchindex.hpp"

#include "searchcore.h"

#include <QByteArray>
#include <QVector>

#include <algorithm>
#include <cstddef>

struct SearchIndex::Private {
	struct Entry {
		QVariant item;
		QString key;
	};

	OmdeIndex* index = omde_index_new();
	QVector<Entry> entries;

	~Private() {
		omde_index_free(index);
	}
};

SearchIndex::SearchIndex(QObject* parent): QObject(parent), mData(std::make_unique<Private>()) {
}

SearchIndex::~SearchIndex() = default;

int SearchIndex::count() const {
	return static_cast<int>(mData->entries.size());
}

void SearchIndex::clear() {
	if (mData->entries.isEmpty())
		return;
	omde_index_clear(mData->index);
	mData->entries.clear();
	emit countChanged();
}

void SearchIndex::add(const QVariant& item, const QString& name, const QStringList& words,
	const QString& key) {
	const QByteArray nameUtf8 = name.toUtf8();
	const QByteArray wordsUtf8 = words.join(QLatin1Char(' ')).toUtf8();
	const QByteArray keyUtf8 = key.toUtf8();
	omde_index_add(mData->index, nameUtf8.constData(), wordsUtf8.constData(), keyUtf8.constData());
	mData->entries.append({item, key});
	emit countChanged();
}

QVariantList SearchIndex::rank(const QString& query, int limit, const QVariantMap& boosts) const {
	const QVector<size_t> indices = rankIndices(query, limit, boosts);
	QVariantList results;
	results.reserve(static_cast<qsizetype>(indices.size()));
	for (const size_t index: indices)
		results.append(mData->entries.at(static_cast<qsizetype>(index)).item);
	return results;
}

QStringList SearchIndex::rankKeys(const QString& query, int limit, const QVariantMap& boosts) const {
	const QVector<size_t> indices = rankIndices(query, limit, boosts);
	QStringList results;
	results.reserve(static_cast<qsizetype>(indices.size()));
	for (const size_t index: indices)
		results.append(mData->entries.at(static_cast<qsizetype>(index)).key);
	return results;
}

QVector<size_t> SearchIndex::rankIndices(const QString& query, int limit,
	const QVariantMap& boosts) const {
	if (limit <= 0 || mData->entries.isEmpty())
		return {};

	QVector<QByteArray> boostKeys;
	QVector<int> boostValues;
	boostKeys.reserve(boosts.size());
	boostValues.reserve(boosts.size());
	for (auto it = boosts.cbegin(); it != boosts.cend(); ++it) {
		boostKeys.append(it.key().toUtf8());
		boostValues.append(it.value().toInt());
	}

	// The vectors keep the UTF-8 alive for the duration of the call.
	QVector<const char*> boostKeyPointers;
	boostKeyPointers.reserve(boostKeys.size());
	for (const QByteArray& key: boostKeys)
		boostKeyPointers.append(key.constData());

	const QByteArray queryUtf8 = query.toUtf8();
	QVector<size_t> indices(limit);
	const size_t found = std::min(
		omde_index_rank(mData->index, queryUtf8.constData(), static_cast<size_t>(limit),
			boostKeyPointers.isEmpty() ? nullptr : boostKeyPointers.constData(),
			boostValues.isEmpty() ? nullptr : boostValues.constData(),
			static_cast<size_t>(boostValues.size()), indices.data()),
		static_cast<size_t>(limit));
	indices.resize(static_cast<qsizetype>(found));
	return indices;
}
