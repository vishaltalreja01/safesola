//
//  MessageComposeView.swift
//  safesola_app
//
//  Created by Foundation 13 on 05/03/26.
//

import SwiftUI
import MessageUI

struct MessageComposeView: UIViewControllerRepresentable {
    var recipients: [String]
    var body: String
    @Binding var isPresented: Bool

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        var parent: MessageComposeView

        init(_ parent: MessageComposeView) {
            self.parent = parent
        }

        func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
            // Dismiss the sheet when the user hits "Send" or "Cancel"
            parent.isPresented = false
            controller.dismiss(animated: true)
            
        }
    }
}
