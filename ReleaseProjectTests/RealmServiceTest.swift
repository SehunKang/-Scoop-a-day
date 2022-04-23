//
//  RealmServiceTest.swift
//  ReleaseProjectTests
//
//  Created by Sehun Kang on 2022/04/22.
//

import XCTest
import RealmSwift
import RxBlocking
import RxSwift

@testable import ReleaseProject
class RealmServiceTest: XCTestCase {
    
    var task: RealmServiceType!

    override func setUpWithError() throws {
        task = RealmService()
    }

    override func tearDownWithError() throws {
        
    }

    func testRealmServiceTest() throws {
        
        //고양이 생성
        guard let cat = try task.createNewCat(catName: "test").toBlocking().first() else {return}
        
        XCTAssertEqual(cat.catName, "test")
        
        //고양이 이름 변경
        _ = try task.changeName(cat: cat, newName: "newName").toBlocking().first()
        
        XCTAssertEqual(cat.catName, "newName")
        
        // 고양이 정보
        guard let poopCount = cat.dailyDataList.last?.poopCount,
        let urineCount = cat.dailyDataList.last?.urineCount,
        let date = cat.dailyDataList.last?.date
        else {return}
        
        XCTAssertEqual(poopCount, 0)
        XCTAssertEqual(urineCount, 0)
        XCTAssertEqual(date, Date().removeTime())
        
        //고양이 맛동산 수 수정
        let newValueForTest = 3
        _ = try task.changeCount(cat: cat, date: Date().removeTime(), type: .poo, value: newValueForTest).toBlocking().first()
        
        guard let newPoopCount = cat.dailyDataList.last?.poopCount else {return}
        
        XCTAssertEqual(newPoopCount, newValueForTest)
        
        //RxDataSources를 위한 Observable 테스트
        let taskCat = task.taskOn()
        
        guard let blockedObservableValue = try taskCat.toBlocking().first()?.last else {return}
        let taskCatName = blockedObservableValue.catName
        let taskCatCreateDate = blockedObservableValue.createDate
        let taskCatPooCount = blockedObservableValue.dailyDataList.last!.poopCount
        let taskCatPeeCount = blockedObservableValue.dailyDataList.last!.urineCount
        
        XCTAssertEqual(taskCatName, "newName")
        XCTAssertEqual(taskCatCreateDate, Date().removeTime())
        XCTAssertEqual(taskCatPooCount, newValueForTest)
        XCTAssertEqual(taskCatPeeCount, 0)
        
        //고양이 삭제 테스트
        _ = try task.delete(cat: cat).toBlocking().first()
        
        XCTAssertEqual(cat.isInvalidated, true)
    }
    


}
