//
//  WorkoutCellTests.swift
//  Smart Swim Tests
//
//  Created by Artem Tkachuk on 05.04.2025.
//

import XCTest
@testable import Smart_Swim

final class WorkoutCellTests: XCTestCase {
    // MARK: - Subject Under Test
    var sut: WorkoutCell!
    
    // MARK: - Test Doubles
    class WorkoutCellDelegateSpy: WorkoutCellDelegate {
        var editCalled = false
        var deletionCalled = false
        var editedCell: WorkoutCell?
        var deletedCell: WorkoutCell?
        
        func workoutCellDidRequestEdit(_ cell: WorkoutCell) {
            editCalled = true
            editedCell = cell
        }
        
        func workoutCellDidRequestDeletion(_ cell: WorkoutCell) {
            deletionCalled = true
            deletedCell = cell
        }
    }
    
    // MARK: - Test Lifecycle
    override func setUp() {
        super.setUp()
        configureWorkoutCell()
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Test Configure
    func configureWorkoutCell() {
        sut = WorkoutCell(style: .default, reuseIdentifier: "TestCell")
    }
    
    // MARK: - Test Cases
    func testCellConfiguration() {
        // Arrange
        let workout = WorkoutModels.FetchWorkouts.ViewModel.DisplayedWorkout(
            name: "Test Workout",
            totalVolume: 1000,
            exercises: [
                "1. Разминка 100м кроль",
                "2. 8x50м на спине",
                "3. Заминка 200м брасс"
            ]
        )
        
        // Act
        sut.configure(with: workout)
        
        // Assert
        let mirror = Mirror(reflecting: sut as Any)
        if let nameLabelProperty = mirror.children.first(where: { $0.label == "nameLabel" }) {
            if let nameLabel = nameLabelProperty.value as? UILabel {
                XCTAssertEqual(nameLabel.text, "Test Workout")
            }
        }
        
        if let volumeLabelProperty = mirror.children.first(where: { $0.label == "volumeLabel" }) {
            if let volumeLabel = volumeLabelProperty.value as? UILabel {
                XCTAssertEqual(volumeLabel.text, "Всего: 1000м")
            }
        }
        
        if let stackViewProperty = mirror.children.first(where: { $0.label == "exercisesStackView" }) {
            if let stackView = stackViewProperty.value as? UIStackView {
                XCTAssertEqual(stackView.arrangedSubviews.count, 3)
            }
        }
    }
}
