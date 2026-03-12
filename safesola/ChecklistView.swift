//
//  ContentView.swift
//  Checklist
//
//  Created by Foundation 27 on 05/03/26.
//

import SwiftUI

struct ChecklistView: View {
    
    struct ChecklistItem: Identifiable {
        let id = UUID()
        var title: String
        var isChecked: Bool
    }
    
    @State private var documents: [ChecklistItem] = [
        ChecklistItem(title: "Check the safest areas of the city on the map and make sure your accommodation is there", isChecked: false),
        ChecklistItem(title: "Be aware of pickpocketing, especially in crowded places", isChecked: false),
        ChecklistItem(title: "Save your accommodation’s full address offline", isChecked: false)
    ]
    
    var body: some View {
        NavigationStack {
            List {
                
                Section(header: Text("Safety Awarness")
                    .font(.headline).foregroundColor(.appAccent)) {
                        
                        ForEach($documents) { $item in
                            HStack {
                                Button {
                                    item.isChecked.toggle()
                                } label: {
                                    Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(item.isChecked ? .appAccent : .gray)
                                }
                                
                                Text(item.title)
                                    .strikethrough(item.isChecked)
                            }
                            .listRowBackground(Color(UIColor.systemGroupedBackground))
                        }
                    }
                
                Section(header: Text("Transportation")
                    .font(.headline).foregroundColor(.appAccent)) {
                        
                        ChecklistRow(title: "Plan how to travel between the airport/station and your accommodation")
                        ChecklistRow(title: "Check transport schedules, especially late at night")
                        ChecklistRow(title: "Use only licensed taxis (official numbers: 0812222, 081888)")
                    }
                
                Section(header: Text("Documents and Entry Requirements")
                    .font(.headline).foregroundColor(.appAccent)) {
                        
                        ChecklistRow(title: "Check required travel documents (ID, passport, visa)")
                        ChecklistRow(title: "Save digital copies of important documents")
                    }
                
                Section(header: Text("Emergency and Safety Tools")
                    .font(.headline).foregroundColor(.appAccent)) {
                        
                        ChecklistRow(title: "Find your country’s embassy or consulate and save the contact")
                        ChecklistRow(title: "Check your travel insurance and emergency contact details")
                        ChecklistRow(title: "Add trusted emergency contacts in the app")
                    }
                Section(header: Text("Money and Payments")
                    .font(.headline).foregroundColor(.appAccent)) {
                        
                        ChecklistRow(title: "Bring some cash (euros); not all places accept cards")
                        ChecklistRow(title: "Make sure your credit/debit card works in Naples")
                    }
                Section(header: Text("Connectivity")
                    .font(.headline).foregroundColor(.appAccent)) {
                        
                        ChecklistRow(title: "Check if your SIM works in Naples; otherwise get a local SIM or eSIM")
                    }
            }
            
            .navigationTitle("SafeList")
            .scrollContentBackground(.hidden)
            .background(Color.white)
        }
    }
}

struct ChecklistRow: View {
    let title: String
    @State private var checked = false
    
    var body: some View {
        HStack {
            Button {
                checked.toggle()
            } label: {
                Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(checked ? .appAccent : .gray)
            }
            
            Text(title)
                .strikethrough(checked)
        }
        .listRowBackground(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    ChecklistView()
}
