//
//  ContentView.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 11/10/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            CountryListView()
                .navigationDestination(for: Country.self) { c in
                    CountryScoreCard(name: c.name, score: c.score, advisoryLevel: c.advisoryLevel)
                        .padding()
                        .navigationTitle(c.name)
                        .navigationBarTitleDisplayMode(.inline)
                }
        }
    }
}
