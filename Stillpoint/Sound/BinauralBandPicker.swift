import SwiftUI

/// Chooses the beat frequency for binaural tones, with an honest note about the evidence.
struct BinauralBandPicker: View {
    var selection: BinauralBand
    var select: (BinauralBand) -> Void

    @State private var draft = BinauralBand.alpha

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("Beat frequency")
                .font(.headline)
            Picker("Beat frequency", selection: $draft) {
                ForEach(BinauralBand.allCases) { band in
                    Text(band.shortTitle).tag(band)
                }
            }
            .pickerStyle(.segmented)
            Text("\(draft.title). Some people find these tones help them settle; the research is mixed, so trust your ears.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear(perform: syncDraft)
        .onChange(of: draft) { _, newValue in
            select(newValue)
        }
    }

    private func syncDraft() {
        draft = selection
    }
}
