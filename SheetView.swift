import SwiftUI
import MapKit

struct SheetView: View {
    @State private var search: String = ""
    @EnvironmentObject var locationManager: LocationManager
    @Binding var searchResults: [SearchResult]
    @Binding var selectedLocation: SearchResult?
    @Binding var mapCenterCoordinate: CLLocationCoordinate2D?
    
    var body: some View {
        VStack {
            // 1
            HStack {
                Image(systemName: "magnifyingglass")
                TextField("Enter location", text: $search)
                    .autocorrectionDisabled()
                    .onSubmit {
                        Task {
                            do {
                                print("change in search results, inside")
                                searchResults = (try? await locationManager.search(with: search, coordinate: mapCenterCoordinate)) ?? []
                            }
                        }
                    }
            }
            .modifier(TextFieldGrayBackgroundColor())

            Spacer()
            List {
                ForEach(locationManager.completions) { completion in
                    Button(action: { didTapOnCompletion(completion) }) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(completion.title)
                                .font(.headline)
                                .fontDesign(.rounded)
                            Text(completion.subTitle)
                            if let url = completion.url {
                                Link(url.absoluteString, destination: url)
                                    .lineLimit(1)
                            }
                        }
                    }
                    .onTapGesture {
                        didTapOnCompletion(completion)
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .onChange(of: search) {
                    locationManager.update(queryFragment: search)
                }
        .padding()
        .interactiveDismissDisabled()
        .presentationDetents([.height(200), .large])
        .presentationBackground(.regularMaterial)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
    }
    private func didTapOnCompletion(_ completion: SearchCompletions) {
        Task {
            if let singleLocation = try? await locationManager.search(with: "\(completion.title) \(completion.subTitle)", coordinate: mapCenterCoordinate).first {
                selectedLocation = singleLocation
            }
        }
    }
}

struct TextFieldGrayBackgroundColor: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(.gray.opacity(0.1))
            .cornerRadius(8)
            .foregroundColor(.primary)
    }
}



