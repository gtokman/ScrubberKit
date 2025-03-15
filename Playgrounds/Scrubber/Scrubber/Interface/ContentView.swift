//
//  ContentView.swift
//  Scrubber
//
//  Created by 秋星桥 on 2/18/25.
//

import SwiftUI

struct ContentView: View {
    @State var searchQuery: String = ""
    @State var enableURLsReranker: Bool = false
    @State var enableBM5Reranker: Bool = true
    @State var keepKPerHostname: Int? = 4
    @State var vm: ViewModel? = nil

    var body: some View {
        VStack(spacing: 16) {
            Text("ScrubberKit - Generate Search Report")
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
            TextField("Search...", text: $searchQuery)
                .textFieldStyle(.plain)
                .padding(8)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onSubmit { begin() }
                .sheet(item: $vm) { item in
                    SearchProgressView(vm: item)
                }
                .frame(maxWidth: 500)
                .padding()
            Button {
                begin()
            } label: {
                Image(systemName: "arrow.right.circle.fill")
                    .foregroundStyle(.blue)
                    .font(.largeTitle)
            }
            .buttonStyle(.plain)
            .underline()
            .disabled(searchQuery.isEmpty)

            HStack {
                Toggle("URLs Reranker", isOn: $enableURLsReranker)
                    .toggleStyle(.switch)
                if enableURLsReranker {
                    Toggle("BM5 Reranker", isOn: $enableBM5Reranker)
                        .toggleStyle(.switch)
                }
                Spacer()
            }
            .frame(maxWidth: 500)
            if enableURLsReranker {
                Slider(
                    value: Binding(get: {
                        Double(keepKPerHostname ?? 0)
                    }, set: {
                        keepKPerHostname = $0 == 0 ? nil : Int($0)
                    }),
                    in: 0 ... 10,
                    step: 1,
                    minimumValueLabel: Text("0"),
                    maximumValueLabel: Text("10"),
                    label: {
                        Text("Keep Top \(keepKPerHostname ?? 0) Per Hostname")
                    }
                )
                .frame(maxWidth: 500)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    func begin() {
        let query = searchQuery
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        vm = ViewModel(
            query: query,
            enableURLsReranker: enableURLsReranker,
            enableBM5Reranker: enableBM5Reranker,
            keepKPerHostname: keepKPerHostname
        )
    }
}

#Preview {
    ContentView()
        .frame(width: 600, height: 300)
}
