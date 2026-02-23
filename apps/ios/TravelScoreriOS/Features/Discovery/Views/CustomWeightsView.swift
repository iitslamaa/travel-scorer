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
    
    // MARK: - Derived State
    
    private var totalWeight: Double {
        weightsStore.weights.advisory +
        weightsStore.weights.visa +
        weightsStore.weights.affordability
    }
    
    private var isZeroSum: Bool {
        totalWeight <= 0.0001
    }
    
    var body: some View {
        Form {
            
            Section(header: Text("Customize Your Travel Priorities")) {
                
                if isZeroSum {
                    Text("At least one category must have weight.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                
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
            }
            
            Section {
                Button("Save Preferences") {
                    Task {
                        await saveWeightsToBackend()
                    }
                }
                .disabled(sessionManager.userId == nil || isSaving || isZeroSum)

                Button("Reset to Default") {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        weightsStore.resetToDefault()
                    }
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Travel Preferences")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - Slider
    
    private func weightSlider(title: String, value: Binding<Double>) -> some View {
        let percentage: Double = totalWeight > 0
            ? (value.wrappedValue / totalWeight) * 100
            : 0

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
    
    // MARK: - Save
    
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
                let visa: Double
                let affordability: Double
            }

            let row = PreferencesRow(
                user_id: userId,
                advisory: weightsStore.weights.advisory,
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
