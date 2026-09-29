import Foundation

enum LessonMarkdownLoader {
    static func parseModule(markdown: String, path: String) throws -> LessonModule {
        let document = try StrictFrontMatterParser.parse(markdown: markdown, path: path)
        let type = try document.requireString("type", path: path)
        guard type == "module" else {
            throw ContentError("\(path): expected module front matter")
        }
        let id = try document.requireString("id", path: path)
        let categoryId = try document.requireString("categoryId", path: path)
        let order = try document.requirePositiveInteger("order", path: path)
        let module = LessonModule(
            type: type,
            id: id,
            categoryId: categoryId,
            order: order,
            title: try document.requireLocalizedTitle(path: path),
            lessonIds: try document.requireStringArray("lessonIds", path: path),
            status: try document.requireStatus("status", path: path, typeName: "module"),
            bodyMarkdown: document.bodyMarkdown,
            path: path
        )
        guard categoryIdForModuleId(id) == categoryId else {
            throw ContentError("\(path): module categoryId \(categoryId) must match \(id) as \(categoryIdForModuleId(id) ?? "<unknown>")")
        }
        guard (1...8).contains(order) else {
            throw ContentError("\(path): module order must be 1 through 8")
        }
        return module
    }

    static func parseLesson(markdown: String, path: String) throws -> Lesson {
        let document = try StrictFrontMatterParser.parse(markdown: markdown, path: path)
        let type = try document.requireString("type", path: path)
        guard type == "lesson" else {
            throw ContentError("\(path): expected lesson front matter")
        }
        let id = try document.requireString("id", path: path)
        let moduleId = try document.requireString("moduleId", path: path)
        let categoryIds = try document.requireStringArray("categoryIds", path: path)
        let lesson = Lesson(
            type: type,
            id: id,
            moduleId: moduleId,
            categoryIds: categoryIds,
            title: try document.requireLocalizedTitle(path: path),
            covers: try document.requireStringArray("covers", path: path),
            objectives: try document.requireStringArray("objectives", path: path),
            prerequisites: try document.requireStringArray("prerequisites", path: path, allowEmpty: true),
            estimatedMinutes: try document.requirePositiveInteger("estimatedMinutes", path: path),
            quizIds: try document.requireStringArray("quizIds", path: path, allowEmpty: true),
            status: try document.requireStatus("status", path: path, typeName: "lesson"),
            bodyMarkdown: document.bodyMarkdown,
            path: path
        )
        guard let expectedModuleId = moduleIdForLessonId(id) else {
            throw ContentError("\(path): lesson id must match L-001-00 through L-008-00")
        }
        guard expectedModuleId == moduleId else {
            throw ContentError("\(path): lesson moduleId \(moduleId) must match lesson id prefix \(expectedModuleId)")
        }
        let expectedCategoryId = categoryIdForModuleId(moduleId)
        guard let expectedCategoryId, categoryIds.contains(expectedCategoryId) else {
            throw ContentError("\(path): lesson categoryIds must include \(expectedCategoryId ?? "the module category")")
        }
        return lesson
    }

    static func documentType(markdown: String, path: String) throws -> String {
        try StrictFrontMatterParser.parse(markdown: markdown, path: path).requireString("type", path: path)
    }

    private static func categoryIdForModuleId(_ moduleId: String) -> String? {
        guard moduleId.count == 2, moduleId.first == "M", let number = moduleId.last, let integer = Int(String(number)), (1...8).contains(integer) else {
            return nil
        }
        return "B-00\(number)"
    }

    private static func moduleIdForLessonId(_ lessonId: String) -> String? {
        let parts = lessonId.split(separator: "-")
        guard parts.count == 3,
              parts[0] == "L",
              parts[1].count == 3,
              parts[1].hasPrefix("00"),
              let number = parts[1].last,
              let integer = Int(String(number)),
              (1...8).contains(integer),
              parts[2].count == 2,
              parts[2].allSatisfy({ $0.isNumber }) else {
            return nil
        }
        return "M\(number)"
    }
}
