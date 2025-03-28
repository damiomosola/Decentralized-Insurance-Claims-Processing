import { describe, it, expect, beforeEach } from "vitest"

// Mock the Clarity contract environment
const mockBlockHeight = 100
const mockTxSender = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
const mockPolicies = new Map()
let mockNextPolicyId = 1

// Mock contract functions
const policyManagement = {
  getPolicy: (policyId: number) => {
    return mockPolicies.get(policyId) || null
  },
  
  isPolicyActive: (policyId: number) => {
    const policy = mockPolicies.get(policyId)
    if (!policy) return false
    return policy.active && mockBlockHeight < policy.endBlock
  },
  
  createPolicy: (coverageAmount: number, premium: number, duration: number) => {
    const policyId = mockNextPolicyId
    const startBlock = mockBlockHeight
    const endBlock = startBlock + duration
    
    // Simulate STX balance check
    if (premium > 1000) {
      return { error: 103 } // ERR-INSUFFICIENT-FUNDS
    }
    
    mockPolicies.set(policyId, {
      owner: mockTxSender,
      coverageAmount,
      premium,
      startBlock,
      endBlock,
      active: true,
    })
    
    mockNextPolicyId++
    return { value: policyId }
  },
  
  cancelPolicy: (policyId: number) => {
    const policy = mockPolicies.get(policyId)
    if (!policy) {
      return { error: 102 } // ERR-POLICY-NOT-FOUND
    }
    
    if (policy.owner !== mockTxSender) {
      return { error: 100 } // ERR-NOT-AUTHORIZED
    }
    
    policy.active = false
    mockPolicies.set(policyId, policy)
    return { value: true }
  },
}

describe("Policy Management Contract", () => {
  beforeEach(() => {
    // Reset the mock state
    mockPolicies.clear()
    mockNextPolicyId = 1
  })
  
  it("should create a new policy", () => {
    const result = policyManagement.createPolicy(10000, 500, 1000)
    expect(result).toHaveProperty("value")
    expect(result.value).toBe(1)
    
    const policy = policyManagement.getPolicy(1)
    expect(policy).not.toBeNull()
    expect(policy.coverageAmount).toBe(10000)
    expect(policy.premium).toBe(500)
    expect(policy.active).toBe(true)
  })
  
  it("should fail to create a policy with insufficient funds", () => {
    const result = policyManagement.createPolicy(10000, 1500, 1000)
    expect(result).toHaveProperty("error")
    expect(result.error).toBe(103) // ERR-INSUFFICIENT-FUNDS
  })
  
  it("should cancel an existing policy", () => {
    // First create a policy
    policyManagement.createPolicy(10000, 500, 1000)
    
    // Then cancel it
    const result = policyManagement.cancelPolicy(1)
    expect(result).toHaveProperty("value")
    expect(result.value).toBe(true)
    
    const policy = policyManagement.getPolicy(1)
    expect(policy.active).toBe(false)
  })
  
  it("should fail to cancel a non-existent policy", () => {
    const result = policyManagement.cancelPolicy(999)
    expect(result).toHaveProperty("error")
    expect(result.error).toBe(102) // ERR-POLICY-NOT-FOUND
  })
  
  it("should correctly determine if a policy is active", () => {
    // Create a policy
    policyManagement.createPolicy(10000, 500, 1000)
    expect(policyManagement.isPolicyActive(1)).toBe(true)
    
    // Cancel the policy
    policyManagement.cancelPolicy(1)
    expect(policyManagement.isPolicyActive(1)).toBe(false)
  })
})

