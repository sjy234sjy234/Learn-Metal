//
//  OrbitControl.hpp
//  Learn-Metal
//
//  Created by  沈江洋 on 25/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#ifndef OrbitControl_hpp
#define OrbitControl_hpp

#include <stdio.h>
#include <simd/simd.h>
#include "MathUtilities.hpp"

using namespace simd;

//left-hand coordinates, suppose camera moving
class OrbitControl
{
    
public:
    OrbitControl();
    void init(float3 target, float3 camera);
    void reset();
    void rotateLeft();
    void rotateRight();
    void rotateUp();
    void rotateDown();
    void zoomIn();
    void zoomOut();
    void toLeftNearest();
    void toRightNearest();
    float4x4 getTransform();
    
private:
    float m_pitch;
    float m_pitchVelocity;
    float2 m_pitchRange;
    
    float m_yaw;
    float m_yawVelocity;
    float2 m_yawRange;
    
    float m_dist;
    float m_distVelocity;
    float2 m_distRange;
    
    float3 m_target;
    float3 m_camera;
    float3 m_perDistTranslate;
    float4x4 m_preTranslate;
    float4x4 m_aftTranslate;
    
    bool m_isInitted;
};

#endif /* OrbitControl_hpp */
