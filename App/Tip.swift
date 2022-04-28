//
//  Tip.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 28.04.22.
//

import Foundation
import StoreKit

@available(macOS 12.0, *)
enum Tip {
	private static var products: [Product] = []
	private static var updateListener: Task<Void, Error>?

	static func getProducts() async -> [Product] {
		guard products.isEmpty else { return products }
		return await fetch()
	}

	static func fetch() async -> [Product] {
		do {
			products = try await Product.products(for: (1...3).map { "de.jandamm.wallamac.tip\($0)" })
			listenForStoreKitUpdates()
		} catch {
			print(error)
		}
		return products
	}

	static func purchase(_ tip: Product, onQueue queue: DispatchQueue = .main, onSuccess: @escaping () -> Void) {
		Task {
			do {
				switch try await tip.purchase() {
				case let .success(.verified(transaction)):
					await transaction.finish()
					handleTransaction(transaction)
					queue.async {
						onSuccess()
					}
				case .success(.unverified),
						.userCancelled,
						.pending:
					break
				@unknown default:
					break
				}

			} catch {
				print(error)
			}
		}
	}

	static func listenForStoreKitUpdates() {
		guard updateListener == nil else { return }
		updateListener = Task {
			for await result in Transaction.updates {
				switch result {
				case let .verified(transaction):
					await transaction.finish()

					handleTransaction(transaction)
				case .unverified:
					break
				}
			}
		}
	}

	static var previousTips: Set<TimeInterval> {
		Set(UserDefaults.standard.array(forKey: purchaseKey) as? Array<TimeInterval> ?? [])
	}

	private static let purchaseKey = "Purchase"
	private static func handleTransaction(_ transaction: Transaction) {
		var purchaseDates = previousTips

		if transaction.revocationDate == nil {
			purchaseDates.insert(transaction.purchaseDate.timeIntervalSince1970)
		} else {
			purchaseDates.remove(transaction.purchaseDate.timeIntervalSince1970)
		}

		UserDefaults.standard.set(Array(purchaseDates), forKey: purchaseKey)
	}
}
