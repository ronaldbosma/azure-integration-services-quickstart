// =================================================================================
// Helper file to call the getInstanceId function in tests and assert the result
// =================================================================================

// Arrange

import { getInstanceId } from '../naming-conventions.bicep'

param environment string
param region string
param instance string

param expectedResult string

// Act
var actualResult = getInstanceId(environment, region, instance)

// Assert
assert assertResult = actualResult == expectedResult
