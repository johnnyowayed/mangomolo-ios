//
//  ImageCarouselView.swift
//  Mangomolo
//
//  Created by Johnny Owayed on 05/05/2025.
//

import SwiftUI

struct ImageCarouselView: View {
    let items: [MediaItem]
    let isSubscribed: Bool

    var body: some View {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { item in
                        NavigationLink(
                            destination: PlayerView(mediaItem: item, isSubscribed: isSubscribed)
                        ) {
                            Image(item.orientation == .portrait ? "robot_portrait" : "robot_landscape")
                                .resizable()
                                .scaledToFill()
                                .frame(
                                    width: item.orientation == .portrait ? 120 : 200,
                                    height: item.orientation == .portrait ? 170 : 120
                                )
                                .clipped()
                                .cornerRadius(12)
                                .scaleEffect(1.0)
                                .animation(.easeInOut(duration: 0.3), value: UUID())
                        }
                    }
                }
            }
    }
}
