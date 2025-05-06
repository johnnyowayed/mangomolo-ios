// Home view SwiftUI
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text(viewModel.isSubscribed ? "✅ Subscribed" : "🔒 Not Subscribed")
                    .font(.subheadline)
                    .foregroundColor(viewModel.isSubscribed ? .green : .red)
                Spacer()
                Toggle("", isOn: $viewModel.isSubscribed)
                    .labelsHidden()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)

            VStack(alignment: .leading) {
                Text("Vertical Carousel")
                    .font(.headline)
                ImageCarouselView(items: viewModel.verticalItems, isSubscribed: viewModel.isSubscribed)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            VStack(alignment: .leading) {
                Text("Horizontal Carousel")
                    .font(.headline)
                ImageCarouselView(items: viewModel.horizontalItems, isSubscribed: viewModel.isSubscribed)
            }
            .padding(.horizontal)
            .padding(.bottom, 12)

            Spacer()
        }
        .navigationTitle("Home")
    }
}


