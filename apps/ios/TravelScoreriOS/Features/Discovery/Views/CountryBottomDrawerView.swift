//
//  CountryBottomDrawerView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 1/22/26.
//

import Foundation
import SwiftUI
import SafariServices

struct CountryBottomDrawerView: View {
    @Environment(\.dismiss) private var dismiss

    let country: WhenToGoCountry

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {

            HStack {
                Text(country.name)
                    .font(.title2).bold()

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            Text("Selected destination")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Score snapshot")
                .font(.headline)

            // TODO: replace with real breakdown fields you already compute
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Seasonality")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScorePill(score: 80)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Affordability")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScorePill(score: 90)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Visa ease")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    ScorePill(score: 100)
                }
            }

            Text("This month is one of the best times to visit based on weather, crowds, and overall conditions. Open the full country page to compare safety, affordability, and visa details.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let url = URL(string: "https://travel-scorer.vercel.app/country/\(country.slug)") {
                NavigationLink {
                    InAppSafariView(url: url)
                        .navigationTitle(country.name)
                        .navigationBarTitleDisplayMode(.inline)
                } label: {
                    HStack {
                        Text("Open full country page")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.systemGray6))
                    )
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            } else {
                Text("Invalid country link")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
    }
}


private struct InAppSafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        let controller = SFSafariViewController(url: url)
        return controller
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No-op
    }
}
