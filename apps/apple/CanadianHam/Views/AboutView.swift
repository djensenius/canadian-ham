import SwiftUI

struct AboutView: View {
    let bank: QuestionBank

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("About canadian-ham")
                    .font(.largeTitle.bold())

                GroupBox("Bank") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Active bank: \(bank.manifest.bankId)")
                        Text("Effective date: \(bank.manifest.effectiveDate)")
                        Text("Questions: \(bank.questions.count) • Categories: \(bank.categories.count) • Subsections: \(bank.subsections.count)")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Attribution and development status") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Question-bank material and related reference material are sourced from Innovation, Science and Economic Development Canada (ISED) Amateur Radio Operator Certificate Basic Qualification materials.")
                        Text("The ISED permission request has been drafted but not yet sent or granted. Until written permission is recorded, this app is for private, non-distributed development only and must not claim written permission has been granted.")
                        Text("Source path: \(bank.manifest.source.path)")
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Disclaimer") {
                    Text("canadian-ham is an independent study tool. It is not affiliated with, sponsored by, or endorsed by the Government of Canada, Innovation, Science and Economic Development Canada (ISED), Radio Amateurs of Canada (RAC), or any accredited examiner.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Privacy") {
                    Text("This Apple app works offline, uses bundled content, includes no networking code, includes no analytics or telemetry, and stores no progress remotely in this first slice.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .frame(maxWidth: 860, alignment: .leading)
        }
        .navigationTitle("About")
    }
}
