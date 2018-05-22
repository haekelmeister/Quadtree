import XCTest
@testable import QuadTree

class QuadTreeTests: XCTestCase {

    func testInsert() {
        let quadtree = QuadTree<String>(BoundingBox(-10, -10, 10, 10))
        
        XCTAssert(quadtree.rootNode.leafs.count == 0)
        
        XCTAssert(quadtree.insert(x: -5, y: 5, content: "first"))
        XCTAssert(quadtree.rootNode.leafs.count == 1)
        
        XCTAssert(quadtree.insert(x: -4, y: 4, content: "second"))
        XCTAssert(quadtree.rootNode.leafs.count == 2)
        
        XCTAssert(quadtree.insert(x: -3, y: 3, content: "third"))
        XCTAssert(quadtree.rootNode.leafs.count == 3)
        
        XCTAssert(quadtree.insert(x: -2, y: 2, content: "fourth"))
        XCTAssert(quadtree.rootNode.leafs.count == 4)
        XCTAssertNil(quadtree.rootNode.northWest)
        XCTAssertNil(quadtree.rootNode.northEast)
        XCTAssertNil(quadtree.rootNode.southWest)
        XCTAssertNil(quadtree.rootNode.southEast)
        
        XCTAssert(quadtree.insert(x: -1, y: 1, content: "fifth"))
        XCTAssert(quadtree.rootNode.leafs.count == 4)
        XCTAssertNotNil(quadtree.rootNode.northWest)
        XCTAssertNotNil(quadtree.rootNode.northEast)
        XCTAssertNotNil(quadtree.rootNode.southWest)
        XCTAssertNotNil(quadtree.rootNode.southEast)
        XCTAssert(quadtree.rootNode.northWest!.leafs.count == 1)
        
        XCTAssert(quadtree.insert(x: 6, y: 1, content: "this goes into the northeast bucket"))
        XCTAssert(quadtree.rootNode.leafs.count == 4)
        XCTAssert(quadtree.rootNode.northWest!.leafs.count == 1)
        XCTAssert(quadtree.rootNode.northEast!.leafs.count == 1)
        XCTAssert(quadtree.rootNode.southEast!.leafs.count == 0)
        XCTAssert(quadtree.rootNode.southWest!.leafs.count == 0)
        
        XCTAssert(quadtree.insert(x: -10, y: -10, content: "this should go to southeast"))
        XCTAssert(quadtree.rootNode.southWest!.leafs.count == 1)
        XCTAssertFalse(quadtree.insert(x: -10, y: -11, content: "this should fail"))
        XCTAssertFalse(quadtree.insert(x: 11, y: 10, content: "this should fail"))
    }
    
    func testGatherData() {
        let quadtree = QuadTree<String>(BoundingBox(-10,-10, 10, 10))
        var results: [String] = Array<String>()
        
        XCTAssert(quadtree.insert(x: -9, y: -9, content: "southWest"))
        XCTAssert(quadtree.insert(x: -8, y: -8, content: "southWest"))
        
        XCTAssert(quadtree.insert(x: -9, y: 9, content: "northWest"))
        XCTAssert(quadtree.insert(x: -8, y: 8, content: "northWest"))
        
        XCTAssert(quadtree.insert(x: 9, y: 9, content: "northEast"))
        XCTAssert(quadtree.insert(x: 8, y: 8, content: "northEast"))
        
        XCTAssert(quadtree.insert(x: 9, y: -9, content: "southEast"))
        XCTAssert(quadtree.insert(x: 8, y: -8, content: "southEast"))
        
        quadtree.gatherData(in: BoundingBox(0, -10, 10, 0)) { content, coordinate in
            results.append(content)
        }
        XCTAssert(results.count == 2)
        XCTAssert(results[0] == "southEast")
        XCTAssert(results[1] == "southEast")
        
        results.removeAll()
        XCTAssert(results.count == 0)
        
        XCTAssert(quadtree.insert(x: -1, y: -1, content: "southWest # -1,-1"))
        XCTAssert(quadtree.insert(x: -1, y:  1, content: "northWest # -1,1"))
        XCTAssert(quadtree.insert(x:  1, y:  1, content: "northEast # 1,1"))
        XCTAssert(quadtree.insert(x:  1, y: -1, content: "southEast # 1,-1"))
        
        quadtree.gatherData(in: BoundingBox(-1, -1, 2, 2)) { content, coordinate in
            results.append(content)
        }
        
        XCTAssert(results.count == 4)
        XCTAssert(results[0] == "northWest # -1,1")
        XCTAssert(results[1] == "northEast # 1,1")
        XCTAssert(results[2] == "southWest # -1,-1")
        XCTAssert(results[3] == "southEast # 1,-1")
    }
}
