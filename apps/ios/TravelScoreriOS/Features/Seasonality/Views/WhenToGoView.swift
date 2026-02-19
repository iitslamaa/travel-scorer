//
//  WhenToGoView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 12/2/25.
//

import Foundation
import SwiftUI

struct WhenToGoView: View {
    @StateObject private var viewModel = SeasonalityViewModel()
    @State private var isDrawerOpen: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                header
                
                monthScroller
                
                if viewModel.isLoading {
                    ProgressView("Loading…")
                        .padding()
                } else if let error = viewModel.loadError {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    content
                }
            }
            .padding()
            .navigationTitle("When to Go")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Load data on first appearance
                if viewModel.peakCountries.isEmpty && viewModel.shoulderCountries.isEmpty {
                    viewModel.loadInitial()
                }
            }
            .sheet(isPresented: $isDrawerOpen) {
                if let selected = viewModel.selectedCountry {
                    NavigationStack {
                        SeasonalityCountryBottomDrawerView(country: selected)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
        }
    }
    
    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("When to Go")
                .font(.title2.bold())
            Text("Select a month to explore where it's peak or shoulder season around the world.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var monthScroller: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(allMonthsMeta) { month in
                    let isSelected = month.id == viewModel.selectedMonth
                    Button {
                        isDrawerOpen = false
                        viewModel.selectedCountry = nil
                        viewModel.selectedMonth = month.id   // 👈 ADD THIS

                        Task {
                            await viewModel.load(forMonth: month.id)
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(month.short.uppercased())
                                .font(.caption2.weight(.semibold))
                            Text(String(format: "%02d", month.id))
                                .font(.caption)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 999)
                                .fill(isSelected ? Color.black : Color(.systemGray6))
                        )
                        .foregroundColor(isSelected ? .white : .primary)
                    }
                }
            }
        }
    }
    
    private var content: some View {
        ScrollView {
            VStack(spacing: 16) {
                selectedMonthSummary
                
                // Peak + Shoulder section
                VStack(spacing: 12) {
                    countryListSection(
                        title: "Peak season",
                        note: "Best weather and overall conditions — usually the busiest and priciest.",
                        countries: viewModel.peakCountries.sorted { ($0.score ?? -1) > ($1.score ?? -1) }
                    )
                    
                    countryListSection(
                        title: "Shoulder season",
                        note: "Still good conditions, often fewer crowds and better value.",
                        countries: viewModel.shoulderCountries.sorted { ($0.score ?? -1) > ($1.score ?? -1) }
                    )
                }
            }
        }
    }
    
    private var selectedMonthSummary: some View {
        let monthMeta = allMonthsMeta.first { $0.id == viewModel.selectedMonth }
        
        return HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Selected month")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(monthMeta?.label ?? "Month \(viewModel.selectedMonth)")
                    .font(.subheadline)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("Peak: \(viewModel.peakCountries.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .clipShape(Capsule())
                Text("Shoulder: \(viewModel.shoulderCountries.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.yellow.opacity(0.1))
                    .clipShape(Capsule())
                Text("Total: \(viewModel.peakCountries.count + viewModel.shoulderCountries.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemGray6))
                    .clipShape(Capsule())
            }
        }
    }
    
    // MARK: - List sections
    
    private func countryListSection(
        title: String,
        note: String,
        countries: [SeasonalityCountry]
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
            Text(note)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if countries.isEmpty {
                Text("No destinations in this category for the selected month.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                WrapChips(countries: countries) { country in
                    viewModel.select(country)
                    isDrawerOpen = true
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

private struct SeasonalityCountryBottomDrawerView: View {
    @Environment(\.dismiss) private var dismiss

    let country: SeasonalityCountry

    // Advisory: map level (1–4) into a 0–100 style score so it fits the same pill UX.
    // Level 1 -> 100, Level 2 -> 75, Level 3 -> 50, Level 4 -> 25
    private var advisoryScore: Double? {
        guard let level = country.advisoryLevel else { return nil }
        let clamped = min(max(level, 1), 4)
        return Double(5 - clamped) * 25.0
    }

    private var advisorySubtitle: String? {
        guard let level = country.advisoryLevel else { return nil }
        return "Level \(level)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Text((country.region ?? "").uppercased())
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 10) {
                scoreRow(title: "Advisory", value: advisoryScore, subtitle: advisorySubtitle)
                scoreRow(title: "Affordability", value: country.scores?.affordability)
                scoreRow(title: "Visa ease", value: country.scores?.visaEase)
                scoreRow(title: "Seasonality", value: country.scores?.seasonality)
            }
            .padding(12)
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Text("Open the full country page to compare safety, affordability, and visa details.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(16)
        .navigationBarHidden(true)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 10) {
                    Text(country.name ?? "Unknown")
                        .font(.title2.bold())

                    Spacer()

                    // Overall score pill next to title
                    ScorePill(score: country.score ?? 0)
                }
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Rows + Pills

    private func scoreRow(title: String, value: Double?, subtitle: String? = nil) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            ScorePill(score: value ?? 0)
        }
        .padding(.vertical, 6)
    }
}
