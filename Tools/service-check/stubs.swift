import Foundation
struct FetchDescriptor<T> { init() {} }
struct SaveFailure: Error {}
final class ModelContext {
    var objects: [AnyObject] = []; var saves = 0; var failNextSave = false; var rollbacks = 0
    func insert(_ o: AnyObject) { if !objects.contains(where: { $0 === o }) { objects.append(o) } }
    func fetch<T: AnyObject>(_ d: FetchDescriptor<T>) throws -> [T] { objects.compactMap { $0 as? T } }
    func save() throws { if failNextSave { failNextSave = false; throw SaveFailure() }; saves += 1 }
    func rollback() { rollbacks += 1 }
}
