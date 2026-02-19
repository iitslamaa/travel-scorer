//
//  FriendsSection.swift
//  TravelScoreriOS
//
//  Created by Lama Yassine on 2/13/26.
//

import Foundation
import SwiftUI

struct FriendsSection: View {
    
    let relationshipState: RelationshipState
    let friendCount: Int
    let onToggleFriend: () async -> Void
    let onCancelRequest: () async -> Void
    
    @State private var showDrawer = false
    @State private var showUnfriendConfirmation = false
    
    var body: some View {
        Button {
            showDrawer = true
        } label: {
            HStack {
                Label("Friends", systemImage: "person.2.fill")
                    .font(.headline)
                
                Spacer()
                
                Text("\(friendCount)")
                    .foregroundStyle(.secondary)
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal)
        }
        .sheet(isPresented: $showDrawer) {
            drawerView
                .presentationDetents([.medium])
        }
    }
    
    private var drawerView: some View {
        VStack(spacing: 24) {
            
            if relationshipState == .friends {
                Button(role: .destructive) {
                    showUnfriendConfirmation = true
                } label: {
                    Text("Unfriend")
                        .frame(maxWidth: .infinity)
                }
            }
            
            if relationshipState == .requestSent {
                Button(role: .destructive) {
                    Task { await onCancelRequest() }
                } label: {
                    Text("Cancel Friend Request")
                        .frame(maxWidth: .infinity)
                }
            }
            
            Spacer()
        }
        .padding()
        .alert("Unfriend?", isPresented: $showUnfriendConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Confirm", role: .destructive) {
                Task { await onToggleFriend() }
            }
        }
    }
}
