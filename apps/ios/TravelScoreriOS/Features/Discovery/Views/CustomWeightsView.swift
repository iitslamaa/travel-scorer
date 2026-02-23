//
//  CustomWeightsView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/22/26.
//

import Foundation
import SwiftUI
import Supabase

struct CustomWeightsView: View {
    
    @EnvironmentObject private var weightsStore: ScoreWeightsStore
    @EnvironmentObject private var sessionManager: SessionManager
    @State private var isSaving: Bool = false
    
    var body: some View {
        Form {
            Section(header: Text("Customize Your Travel Priorities")) {
                
                weightSlider(
                    title: "Affordability",
                    value: $weightsStore.weights.affordability
                )

                weightSlider(
                    title: "Visa Ease",
                    value: $weightsStore.weights.visa
                )

                weightSlider(
                    title: "Travel Advisory",
                    value: $weightsStore.weights.advisory
                )

                weightSlider(
                    title: "Seasonality",
                    value: $weightsStore.weights.seasonality
                )
            }
            
            Section {
                Button("Save Preferences") {
                    Task {
                        await saveWeightsToBackend()
                    }
                }
                .disabled(sessionManager.userId == nil || isSaving)

                Button("Reset to Default") {
                    weightsStore.resetToDefault()
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Travel Preferences")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func weightSlider(title: String, value: Binding<Double>) -> some View {
        let totalWeight =
            weightsStore.weights.advisory +
            weightsStore.weights.seasonality +
            weightsStore.weights.visa +
            weightsStore.weights.affordability

        let percentage: Double
        if totalWeight > 0 {
            percentage = (value.wrappedValue / totalWeight) * 100
        } else {
            percentage = 0
        }

        return VStack(alignment: .leading) {
            HStack {
                Text(title)
                Spacer()
                Text(String(format: "%.0f%%", percentage))
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: 0...1, step: 0.05)
        }
        .padding(.vertical, 6)
    }
    
    private func saveWeightsToBackend() async {
        guard let userId = sessionManager.userId else { return }

        isSaving = true
        defer { isSaving = false }

        guard
            let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
            let anonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
            let url = URL(string: urlString)
        else {
            print("❌ Missing Supabase config")
            return
        }

        let client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: anonKey
        )

        do {
            struct PreferencesRow: Encodable {
                let user_id: UUID
                let advisory: Double
                let seasonality: Double
                let visa: Double
                let affordability: Double
            }

            let row = PreferencesRow(
                user_id: userId,
                advisory: weightsStore.weights.advisory,
                seasonality: weightsStore.weights.seasonality,
                visa: weightsStore.weights.visa,
                affordability: weightsStore.weights.affordability
            )

            try await client
                .from("user_score_preferences")
                .upsert(row)
                .execute()

            print("✅ Weights saved to Supabase")
        } catch {
            print("❌ Failed saving weights:", error)
        }
    }
}
