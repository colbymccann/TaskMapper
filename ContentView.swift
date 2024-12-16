//
//  ContentView.swift
//  TaskMapper
//
//  Created by Colby McCann on 8/9/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataController: DataController
    @State private var showTaskView = false
    @State private var showCreateView = false
    var body: some View {
            NavigationView {
                VStack {
                    List(selection: $dataController.selectedTask) {
                        ForEach(dataController.tasksList) { task in
                            RoundedRectangle(cornerRadius: 10)
                                .fill(task.completedColor)
                                .frame(height: 50)
                                .overlay(
                                    Text(task.taskTitle)
                                        .foregroundColor(.white)
                                )
                                .onTapGesture {
                                    showTaskView.toggle()
                                    dataController.selectedTask = task
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                       dataController.delete(task)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    Button {
                                        dataController.toggleCompleted(task: task)
                                    } label: {
                                        Label("Toggle done", systemImage: "checkmark.circle")
                                    }
                                }
                        }
                }
                Spacer()

                    NavigationLink(destination: TravelingSalesmanView()){
                        Text("GENERATE")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.orange)
                            .cornerRadius(20)
                            .padding(.horizontal)
                    }
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(Color.white) // Optional background color for the screen
                    .ignoresSafeArea() // Makes sure the button fills the entire screen
                }
                .navigationTitle("Errands")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showCreateView.toggle()
                        }) {
                            Image(systemName: "plus")
                        }.sheet(isPresented: $showCreateView) {
                            TaskCreationScreen()
                        }
                    }
                }
            }
            .sheet(isPresented: $showTaskView, content: {
                TaskViewScreen(task: dataController.selectedTask!)
            })
        }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        return ContentView().environmentObject(DataController.preview).environmentObject(LocationManager())
    }
}
