//
//  OrbitControl.cpp
//  Learn-Metal
//
//  Created by  沈江洋 on 25/01/2018.
//  Copyright © 2018  沈江洋. All rights reserved.
//

#include "OrbitControl.hpp"

#include <iostream>

OrbitControl::OrbitControl()
{
    m_isInitted=false;
    
    m_pitchVelocity=M_PI/180.0;
    m_pitchRange={-M_PI/3.0,M_PI/3.0};
    
    m_yawVelocity=M_PI/60.0;
    m_yawRange={-M_PI*3.0/4.0,M_PI*3.0/4.0};
    
    m_distVelocity=3.0;
    
    reset();
}

void OrbitControl::init(float3 target, float3 camera)
{
    m_target=target;
    m_camera=camera;
    reset();
    m_isInitted=true;
}

void OrbitControl::reset()
{
    m_pitch=0.0;
    m_yaw=0.0;
    m_dist=length(m_target-m_camera);
    m_distRange={m_dist-80, m_dist+80};
    m_perDistTranslate=normalize(m_target-m_camera);
    m_preTranslate=matrix_float4x4_translation(-m_target);
    m_aftTranslate=matrix_float4x4_translation(m_target);
}

void OrbitControl::rotateLeft()
{
    float newYaw=m_yaw-m_yawVelocity;
    m_yaw=max(newYaw, m_yawRange.x);
}

void OrbitControl::rotateRight()
{
    float newYawe=m_yaw+m_yawVelocity;
    m_yaw=min(newYawe,m_yawRange.y);
}

void OrbitControl::rotateUp()
{
    float newPitch=m_pitch-m_pitchVelocity;
    m_pitch=max(newPitch, m_pitchRange.x);
}

void OrbitControl::rotateDown()
{
    float newPitch=m_pitch+m_pitchVelocity;
    m_pitch=min(newPitch,m_pitchRange.y);
}

void OrbitControl::zoomIn()
{
    float newDist=m_dist-m_distVelocity;
    m_dist=max(newDist, m_distRange.x);
}

void OrbitControl::zoomOut()
{
    float newDist=m_dist+m_distVelocity;
    m_dist=min(newDist,m_distRange.y);
}

void OrbitControl::toLeftNearest()
{
    m_pitch=0.0;
    m_yaw=-M_PI_2;
    m_dist=m_distRange.x;
}

void OrbitControl::toRightNearest()
{
    m_pitch=0.0;
    m_yaw=M_PI_2;
    m_dist=m_distRange.x;
}

float4x4 OrbitControl::getTransform()
{
    if(m_isInitted)
    {
        float3 translateVector=m_dist*m_perDistTranslate;
        float4x4 translate=matrix_float4x4_translation(translateVector);

        float3 axisX={1.0,0.0,0.0};
        float3 axisY={0.0,1.0,0.0};
        float4x4 rotationPitch=matrix_float4x4_rotation(axisX,m_pitch);
        float4 axisY4={0.0,1.0,0.0,1.0};
        float4 upAxisY4=rotationPitch*axisY4;
        float3 upAxisY={upAxisY4.x,upAxisY4.y,upAxisY4.z};
        float4x4 rotationYaw=matrix_float4x4_rotation(upAxisY, m_yaw);
        float4x4 rotation=rotationYaw*rotationPitch;

        float4x4 transform=translate*rotation*m_preTranslate;
        return transform;
    }
    else
    {
        float4 onesFloat4={1.0,1.0,1.0,1.0};
        float4x4 transform=float4x4(onesFloat4);
        return transform;
    }
}

