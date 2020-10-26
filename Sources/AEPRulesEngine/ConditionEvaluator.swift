/*
 Copyright 2020 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

/// A implementation of the `Evaluating` protocol based on  conditional comparison
public class ConditionEvaluator: Evaluating {
    fileprivate let LOG_TAG = "ConditionEvaluator"
    var operators: [String: Any] = [:]
    
    /// evaluates a single parameter with the give operation name
    /// - Parameters:
    ///   - operation: the name of the operation
    ///   - lhs: a single parameter
    /// - Returns: `Result<True>` when the `operation` is defined and the evaluation is success, otherwise, returns `Result` with failure
    public func evaluate<A>(operation: String, lhs: A) -> Result<Bool, RulesFailure> {
        let op = operators[getHash(operation: operation, typeA: A.self)] as? ((A) -> Bool)
        guard let op_ = op else {
            let message = "Operator not defined for \(getHash(operation: operation, typeA: A.self))"
            RulesEngineLog.trace(label: LOG_TAG, message)
            return Result.failure(RulesFailure.missingOperator(message: message))
        }
        return op_(lhs) ? Result.success(true) : Result.failure(.conditionNotMatched(message: "(\(String(describing: A.self))(\(lhs)) \(operation))"))
    }
    
    /// evaluates two parameters swith the give operation name
    /// - Parameters:
    ///   - operation: the name of the operation
    ///   - lhs: left hand side parameter
    ///   - rhs: right hand side parameter
    /// - Returns: `Result<True>` when the `operation` is defined and the evaluation is success, otherwise, returns `Result` with failure
    public func evaluate<A, B>(operation: String, lhs: A, rhs: B) -> Result<Bool, RulesFailure> {
        let op = operators[getHash(operation: operation, typeA: A.self, typeB: B.self)] as? ((A, B) -> Bool)

        guard let op_ = op else {
            let message = "Operator not defined for \(getHash(operation: operation, typeA: A.self, typeB: B.self))"
            RulesEngineLog.trace(label: LOG_TAG, message)
            return Result.failure(RulesFailure.missingOperator(message: message))
        }
        return op_(lhs, rhs) ? Result.success(true) : Result.failure(.conditionNotMatched(message: "\(String(describing: A.self))(\(lhs)) \(operation) \(String(describing: B.self))(\(rhs))"))
    }
}

/// Defines methods used to register operators
extension ConditionEvaluator {
    
    /// registers a unary operator
    /// - Parameters:
    ///   - operation: the name of the operation
    ///   - closure: the closure used to run the acutally evaluation logic
    public func addUnaryOperator<A>(operation: String, closure: @escaping (A) -> Bool) {
        operators[getHash(operation: operation, typeA: A.self)] = closure
    }
    
    /// registers comparison operator for parameters with different types
    /// - Parameters:
    ///   - operation: the name of the operation
    ///   - closure: the closure used to run the acutally evaluation logic, which accepts two paraemters and return a boolen value
    public func addComparisonOperator<A, B>(operation: String, closure: @escaping (A, B) -> Bool) {
        operators[getHash(operation: operation, typeA: A.self, typeB: B.self)] = closure
    }

    
    /// registers comparison operator for parameters with the same type
    /// - Parameters:
    ///   - operation: the name of the operation
    ///   - :  a `Type` parameter, only used for generic
    ///   - closure: the closure used to run the acutally evaluation logic, which accepts two paraemters and return a boolen value
    public func addComparisonOperator<A>(operation: String, type _: A.Type, closure: @escaping (A, A) -> Bool) {
        operators[getHash(operation: operation, typeA: A.self, typeB: A.self)] = closure
    }

    private func getHash<A, B>(operation: String, typeA _: A.Type, typeB _: B.Type) -> String {
        "\(operation)(\(String(describing: A.self)),\(String(describing: B.self)))"
    }

    private func getHash<A>(operation: String, typeA _: A.Type) -> String {
        "\(operation)(\(String(describing: A.self))\(operation))"
    }
}

/// Defined `init` method and the default set of operators
public extension ConditionEvaluator {
    /// The `OptionSet` used to init a `ConditionEvaluator`
    struct Options: OptionSet {
        public let rawValue: Int
        public static let defaultOptions = Options(rawValue: 1 << 0)
        public static let caseInsensitive = Options(rawValue: 1 << 1)

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    convenience init(options: Options) {
        self.init()
        addDefaultOperators()

        if options.contains(.caseInsensitive) {
            addCaseInSensitiveOperators()
        }
    }

    private func addDefaultOperators() {
        addComparisonOperator(operation: "and", type: Bool.self, closure: { $0 && $1 })
        addComparisonOperator(operation: "or", type: Bool.self, closure: { $0 || $1 })

        addComparisonOperator(operation: "equals", type: String.self, closure: ==)
        addComparisonOperator(operation: "equals", type: Int.self, closure: ==)
        addComparisonOperator(operation: "equals", type: Double.self, closure: ==)
        addComparisonOperator(operation: "equals", type: Bool.self, closure: ==)

        addComparisonOperator(operation: "notEquals", type: String.self, closure: !=)
        addComparisonOperator(operation: "notEquals", type: Int.self, closure: !=)
        addComparisonOperator(operation: "notEquals", type: Double.self, closure: !=)
        addComparisonOperator(operation: "notEquals", type: Bool.self, closure: !=)

        addComparisonOperator(operation: "startsWith", type: String.self, closure: { $0.starts(with: $1) })
        addComparisonOperator(operation: "endsWith", type: String.self, closure: { $0.hasSuffix($1) })
        addComparisonOperator(operation: "contains", type: String.self, closure: { $0.contains($1) })
        addComparisonOperator(operation: "notContains", type: String.self, closure: { !$0.contains($1) })

        addComparisonOperator(operation: "greaterThan", type: Int.self, closure: >)
        addComparisonOperator(operation: "greaterThan", type: Double.self, closure: >)

        addComparisonOperator(operation: "greaterEqual", type: Int.self, closure: >=)
        addComparisonOperator(operation: "greaterEqual", type: Double.self, closure: >=)

        addComparisonOperator(operation: "lessEqual", type: Int.self, closure: <=)
        addComparisonOperator(operation: "lessEqual", type: Double.self, closure: <=)

        addComparisonOperator(operation: "lessThan", type: Int.self, closure: <)
        addComparisonOperator(operation: "lessThan", type: Double.self, closure: <)

        addComparisonOperator(operation: "notExist", type: Any?.self, closure: { lhs, _ in
            lhs == nil
        })
        addComparisonOperator(operation: "exists", type: Any?.self, closure: { lhs, _ in
            lhs != nil
        })
    }

    private func addCaseInSensitiveOperators() {
        addComparisonOperator(operation: "startsWith", type: String.self, closure: { $0.lowercased().starts(with: $1.lowercased()) })
        addComparisonOperator(operation: "equals", type: String.self, closure: { $0.lowercased() == $1.lowercased() })
        addComparisonOperator(operation: "endsWith", type: String.self, closure: { $0.lowercased().hasSuffix($1.lowercased()) })
        addComparisonOperator(operation: "contains", type: String.self, closure: { $0.lowercased().contains($1.lowercased()) })
    }
}
