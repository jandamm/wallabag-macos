//
//  TipViewController.swift
//  Wallabag
//
//  Created by Jan Dammshäuser on 27.04.22.
//

import Cocoa
import StoreKit
import SwiftUI

@available(macOS 12.0, *)
struct TipView: View {
	@State var hasTipped: Bool = false
	@State var hasTippedBefore: Bool = false
	@State var selectedProduct: Product?
	@State var common: String = ""
	@State var products: [Product] = []

	var body: some View {
		Group {
			if !hasTipped {
				VStack(spacing: 8) {
					Text(
						hasTippedBefore
						? "Please consider tipping again."
						: "Please give a tip!"
					)
						.font(.title2)

					Text("This App is free to use.\nBut in order to keep it in the AppStore I need to pay a yearly fee.")
						.font(.footnote)
						.multilineTextAlignment(.center)
						.fixedSize(horizontal: false, vertical: true) // Fix line breaking
				}
					.padding(.horizontal)
					.padding(.bottom, 8)
			} else {
				HStack {
					Image(systemName: "heart.fill")
						.font(.system(.largeTitle))
						.foregroundStyle(.pink)
					Text("Thank you for tipping.")
						.font(.system(.title2))
						.fontWeight(.bold)
				}
				.padding(.top, 16)
				.padding(.bottom, 8)
			}

			if !products.isEmpty {
				HStack {
					ForEach(products) { product in
						Selection(product: product, isSelected: selectedProduct == product)
							.onTapGesture { selectedProduct = product }
					}
				}
				.padding(.bottom, 8)

				if let selectedProduct {
					Button("Tip \(selectedProduct.displayPrice)") {
						Tip.purchase(selectedProduct) {
							hasTipped = true
							hasTippedBefore = true
							products = []
						}
					}
				}
			}
		}
		.task {
			hasTippedBefore = !Tip.previousTips.isEmpty
			products = await Tip.fetch()
				.sorted { $0.id < $1.id }
			selectedProduct = products.last
		}
	}

	struct Selection: View {
		let product: Product
		let isSelected: Bool

		var body: some View {
			VStack {
				Text(product.displayName.replacingOccurrences(of: " ", with: "\n"))
					.font(.headline)
					.multilineTextAlignment(.center)

				Spacer()

				Image(systemName: "heart.fill")
					.font(product.id.last == "1" ? .title3 : product.id.last == "2" ? .title2 : .title)
					.foregroundStyle(.pink)

				Spacer()

				Text(product.displayPrice)
					.font(.subheadline)
			}
			.padding(.vertical)
			.padding(.horizontal, 4)
			.frame(width: 90, height: 120)
			.overlay {
				RoundedRectangle(cornerRadius: 8, style: .continuous)
					.stroke(lineWidth: isSelected ? 2 : 1)
					.foregroundStyle(isSelected ? Color.accentColor : .primary)
					.opacity(isSelected ? 1 : 0.3)
			}
			.contentShape(Rectangle()) // Make everything clickable
		}
	}
}
