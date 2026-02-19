//
//  LegalView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/4/26.
//

import Foundation
import SwiftUI

struct LegalView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text("Legal & Disclaimers")
                    .font(.title2)
                    .fontWeight(.semibold)

                Group {
                    Text("General Information")
                        .font(.headline)

                    Text("""
                    Travel Adventure Finder provides informational travel insights only. All scores, advisories, and recommendations are intended for general guidance and educational purposes. Seasonality insights are based on historical climate averages and typical travel patterns.
                    """)
                }

                Group {
                    Text("Advisories & Safety Scores")
                        .font(.headline)

                    Text("""
                    Safety advisories and scores are derived from publicly available sources and third-party data. Conditions may change rapidly, and Travel Adventure Finder does not guarantee accuracy, completeness, or timeliness.
                    """)
                }

                Group {
                    Text("No Professional Advice")
                        .font(.headline)

                    Text("""
                    Travel Adventure Finder does not provide legal, medical, or governmental advice. Users should verify information with official sources before making travel decisions.
                    """)
                }

                Group {
                    Text("Limitation of Liability")
                        .font(.headline)

                    Text("""
                    Travel Adventure Finder is not responsible for decisions made based on information presented in the app. Use of this app is at your own discretion.
                    """)
                }

                Spacer(minLength: 24)
            }
            .padding()
        }
        .navigationTitle("Legal")
        .navigationBarTitleDisplayMode(.inline)
    }
}
