//=================================================================================
// Helper file to call the getResourceName function in tests and assert the result
//=================================================================================

// Arrange

import { getResourceName } from '../naming-conventions.bicep'

param resourceType string
param environment string
param region string
param instance string

param expectedResult string

// Act
var actualResult = getResourceName(resourceType, environment, region, instance)

// Assert
assert assertResult = actualResult == expectedResult
