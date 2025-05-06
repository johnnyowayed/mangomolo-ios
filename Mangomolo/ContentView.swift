//
//  ContentView.swift
//  Mangomolo
//
//  Created by Johnny Owayed on 05/05/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationView {
            HomeView(viewModel: viewModel)
        }
    }
}
