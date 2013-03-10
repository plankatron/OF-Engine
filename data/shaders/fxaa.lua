-- 
--                     NVIDIA FXAA 3.11 by TIMOTHY LOTTES
--
---------------------------------------------------------------------------------
-- COPYRIGHT (C) 2010, 2011 NVIDIA CORPORATION. ALL RIGHTS RESERVED.
---------------------------------------------------------------------------------
-- TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, THIS SOFTWARE IS PROVIDED
-- *AS IS* AND NVIDIA AND ITS SUPPLIERS DISCLAIM ALL WARRANTIES, EITHER EXPRESS
-- OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL NVIDIA
-- OR ITS SUPPLIERS BE LIABLE FOR ANY SPECIAL, INCIDENTAL, INDIRECT, OR
-- CONSEQUENTIAL DAMAGES WHATSOEVER (INCLUDING, WITHOUT LIMITATION, DAMAGES FOR
-- LOSS OF BUSINESS PROFITS, BUSINESS INTERRUPTION, LOSS OF BUSINESS INFORMATION,
-- OR ANY OTHER PECUNIARY LOSS) ARISING OUT OF THE USE OF OR INABILITY TO USE
-- THIS SOFTWARE, EVEN IF NVIDIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
-- DAMAGES.

fxaadefs = (fxaapreset == 0 and [[
    #define FXAA_QUALITY_PRESET 10
    #define fxaaQualityEdgeThreshold 0.250
    #define fxaaQualityEdgeThresholdMin 0.0833
]] or (fxaapreset == 1 and [[
    #define FXAA_QUALITY_PRESET 12
    #define fxaaQualityEdgeThreshold 0.166
    #define fxaaQualityEdgeThresholdMin 0.0833
]] or (fxaapreset == 2 and [[
    #define FXAA_QUALITY_PRESET 24
    #define fxaaQualityEdgeThreshold 0.125 
    #define fxaaQualityEdgeThresholdMin 0.0625
]] or (fxaapreset == 3 and [[
    #define FXAA_QUALITY_PRESET 39
    #define fxaaQualityEdgeThreshold 0.063 
    #define fxaaQualityEdgeThresholdMin 0.0312
]] or ""))))

fxaadefs = fxaadefs .. [[
    #define fxaaQualitySubpix 0.75

    #if (FXAA_QUALITY_PRESET == 10)
        #define FXAA_QUALITY_PS 3
        #define FXAA_QUALITY_P0 1.5
        #define FXAA_QUALITY_P1 3.0
        #define FXAA_QUALITY_P2 12.0
    #endif
    #if (FXAA_QUALITY_PRESET == 11)
        #define FXAA_QUALITY_PS 4
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 3.0
        #define FXAA_QUALITY_P3 12.0
    #endif
    #if (FXAA_QUALITY_PRESET == 12)
        #define FXAA_QUALITY_PS 5
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 4.0
        #define FXAA_QUALITY_P4 12.0
    #endif
    #if (FXAA_QUALITY_PRESET == 13)
        #define FXAA_QUALITY_PS 6
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 4.0
        #define FXAA_QUALITY_P5 12.0
    #endif
    #if (FXAA_QUALITY_PRESET == 14)
        #define FXAA_QUALITY_PS 7
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 2.0
        #define FXAA_QUALITY_P5 4.0
        #define FXAA_QUALITY_P6 12.0
    #endif
    #if (FXAA_QUALITY_PRESET == 15)
        #define FXAA_QUALITY_PS 8
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 2.0
        #define FXAA_QUALITY_P5 2.0
        #define FXAA_QUALITY_P6 4.0
        #define FXAA_QUALITY_P7 12.0
    #endif
    #if (FXAA_QUALITY_PRESET == 20)
        #define FXAA_QUALITY_PS 3
        #define FXAA_QUALITY_P0 1.5
        #define FXAA_QUALITY_P1 2.0
        #define FXAA_QUALITY_P2 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 21)
        #define FXAA_QUALITY_PS 4
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 22)
        #define FXAA_QUALITY_PS 5
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 23)
        #define FXAA_QUALITY_PS 6
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 2.0
        #define FXAA_QUALITY_P5 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 24)
        #define FXAA_QUALITY_PS 7
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 2.0
        #define FXAA_QUALITY_P5 3.0
        #define FXAA_QUALITY_P6 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 25)
        #define FXAA_QUALITY_PS 8
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 2.0
        #define FXAA_QUALITY_P5 2.0
        #define FXAA_QUALITY_P6 4.0
        #define FXAA_QUALITY_P7 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 26)
        #define FXAA_QUALITY_PS 9
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 2.0
        #define FXAA_QUALITY_P5 2.0
        #define FXAA_QUALITY_P6 2.0
        #define FXAA_QUALITY_P7 4.0
        #define FXAA_QUALITY_P8 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 27)
        #define FXAA_QUALITY_PS 10
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 2.0
        #define FXAA_QUALITY_P5 2.0
        #define FXAA_QUALITY_P6 2.0
        #define FXAA_QUALITY_P7 2.0
        #define FXAA_QUALITY_P8 4.0
        #define FXAA_QUALITY_P9 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 28)
        #define FXAA_QUALITY_PS 11
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 2.0
        #define FXAA_QUALITY_P5 2.0
        #define FXAA_QUALITY_P6 2.0
        #define FXAA_QUALITY_P7 2.0
        #define FXAA_QUALITY_P8 2.0
        #define FXAA_QUALITY_P9 4.0
        #define FXAA_QUALITY_P10 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 29)
        #define FXAA_QUALITY_PS 12
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.5
        #define FXAA_QUALITY_P2 2.0
        #define FXAA_QUALITY_P3 2.0
        #define FXAA_QUALITY_P4 2.0
        #define FXAA_QUALITY_P5 2.0
        #define FXAA_QUALITY_P6 2.0
        #define FXAA_QUALITY_P7 2.0
        #define FXAA_QUALITY_P8 2.0
        #define FXAA_QUALITY_P9 2.0
        #define FXAA_QUALITY_P10 4.0
        #define FXAA_QUALITY_P11 8.0
    #endif
    #if (FXAA_QUALITY_PRESET == 39)
        #define FXAA_QUALITY_PS 12
        #define FXAA_QUALITY_P0 1.0
        #define FXAA_QUALITY_P1 1.0
        #define FXAA_QUALITY_P2 1.0
        #define FXAA_QUALITY_P3 1.0
        #define FXAA_QUALITY_P4 1.0
        #define FXAA_QUALITY_P5 1.5
        #define FXAA_QUALITY_P6 2.0
        #define FXAA_QUALITY_P7 2.0
        #define FXAA_QUALITY_P8 2.0
        #define FXAA_QUALITY_P9 2.0
        #define FXAA_QUALITY_P10 4.0
        #define FXAA_QUALITY_P11 8.0
    #endif
]]

CAPI.shader(0, "fxaa" .. fxaapreset, [[
    void main(void)
    {
        gl_Position = gl_Vertex;
    }
]], ([=[
    #extension GL_ARB_texture_rectangle : enable
    @(fxaadefs)
    uniform sampler2DRect tex0;
    void main(void)
    {
        vec2 posM = gl_FragCoord.xy;
        vec4 rgbyM = texture2DRect(tex0, posM);
        float lumaS = texture2DRect(tex0, posM + vec2( 0.0,  1.0)).a;
        float lumaE = texture2DRect(tex0, posM + vec2( 1.0,  0.0)).a;
        float lumaN = texture2DRect(tex0, posM + vec2( 0.0, -1.0)).a;
        float lumaW = texture2DRect(tex0, posM + vec2(-1.0,  0.0)).a;
        #define lumaM rgbyM.a

        float maxSM = max(lumaS, lumaM);
        float minSM = min(lumaS, lumaM);
        float maxESM = max(lumaE, maxSM);
        float minESM = min(lumaE, minSM);
        float maxWN = max(lumaN, lumaW);
        float minWN = min(lumaN, lumaW);
        float rangeMax = max(maxWN, maxESM);
        float rangeMin = min(minWN, minESM);
        float rangeMaxScaled = rangeMax * fxaaQualityEdgeThreshold;
        float range = rangeMax - rangeMin;
        float rangeMaxClamped = max(fxaaQualityEdgeThresholdMin, rangeMaxScaled);
        bool earlyExit = range < rangeMaxClamped;

        if(earlyExit)
        {
            gl_FragColor = rgbyM;
            return;
        }

        float lumaNW = texture2DRect(tex0, posM + vec2(-1.0, -1.0)).a;
        float lumaSE = texture2DRect(tex0, posM + vec2( 1.0,  1.0)).a;
        float lumaNE = texture2DRect(tex0, posM + vec2( 1.0, -1.0)).a; 
        float lumaSW = texture2DRect(tex0, posM + vec2(-1.0,  1.0)).a;

        float lumaNS = lumaN + lumaS;
        float lumaWE = lumaW + lumaE;
        float subpixRcpRange = 1.0/range;
        float subpixNSWE = lumaNS + lumaWE;
        float edgeHorz1 = (-2.0 * lumaM) + lumaNS;
        float edgeVert1 = (-2.0 * lumaM) + lumaWE;

        float lumaNESE = lumaNE + lumaSE;
        float lumaNWNE = lumaNW + lumaNE;
        float edgeHorz2 = (-2.0 * lumaE) + lumaNESE;
        float edgeVert2 = (-2.0 * lumaN) + lumaNWNE;

        float lumaNWSW = lumaNW + lumaSW;
        float lumaSWSE = lumaSW + lumaSE;
        float edgeHorz4 = (abs(edgeHorz1) * 2.0) + abs(edgeHorz2);
        float edgeVert4 = (abs(edgeVert1) * 2.0) + abs(edgeVert2);
        float edgeHorz3 = (-2.0 * lumaW) + lumaNWSW;
        float edgeVert3 = (-2.0 * lumaS) + lumaSWSE;
        float edgeHorz = abs(edgeHorz3) + edgeHorz4;
        float edgeVert = abs(edgeVert3) + edgeVert4;

        float subpixNWSWNESE = lumaNWSW + lumaNESE;
        bool horzSpan = edgeHorz >= edgeVert;
        float subpixA = subpixNSWE * 2.0 + subpixNWSWNESE;

        if(!horzSpan) lumaN = lumaW;
        if(!horzSpan) lumaS = lumaE;
        float subpixB = (subpixA * (1.0/12.0)) - lumaM;

        float gradientN = lumaN - lumaM;
        float gradientS = lumaS - lumaM;
        float lumaNN = lumaN + lumaM;
        float lumaSS = lumaS + lumaM;
        bool pairN = abs(gradientN) >= abs(gradientS);
        float gradient = max(abs(gradientN), abs(gradientS));
        float lengthSign = pairN ? -1.0 : 1.0;
        float subpixC = clamp(abs(subpixB) * subpixRcpRange, 0.0, 1.0);

        vec2 posB = posM;
        vec2 offNP;
        offNP.x = (!horzSpan) ? 0.0 : 1.0;
        offNP.y = ( horzSpan) ? 0.0 : 1.0;
        if(!horzSpan) posB.x += lengthSign * 0.5;
        if( horzSpan) posB.y += lengthSign * 0.5;

        vec2 posN = posB - offNP * FXAA_QUALITY_P0;
        vec2 posP = posB + offNP * FXAA_QUALITY_P0;
        float subpixD = ((-2.0)*subpixC) + 3.0;
        float lumaEndN = texture2DRect(tex0, posN).a;
        float subpixE = subpixC * subpixC;
        float lumaEndP = texture2DRect(tex0, posP).a;

        if(!pairN) lumaNN = lumaSS;
        float gradientScaled = gradient * 1.0/4.0;
        float lumaMM = lumaM - lumaNN * 0.5;
        float subpixF = subpixD * subpixE;
        bool lumaMLTZero = lumaMM < 0.0;

        lumaEndN -= lumaNN * 0.5;
        lumaEndP -= lumaNN * 0.5;
        bool doneN = abs(lumaEndN) >= gradientScaled;
        bool doneP = abs(lumaEndP) >= gradientScaled;
        if(!doneN) posN -= offNP * FXAA_QUALITY_P1;
        bool doneNP = (!doneN) || (!doneP);
        if(!doneP) posP += offNP * FXAA_QUALITY_P1;

        @(([[
            #if (FXAA_QUALITY_PS > @($i + 2))
            if(doneNP) 
            {
                if(!doneN) lumaEndN = texture2DRect(tex0, posN).a;
                if(!doneP) lumaEndP = texture2DRect(tex0, posP).a;
                if(!doneN) lumaEndN = lumaEndN - lumaNN * 0.5;
                if(!doneP) lumaEndP = lumaEndP - lumaNN * 0.5;
                doneN = abs(lumaEndN) >= gradientScaled;
                doneP = abs(lumaEndP) >= gradientScaled;
                if(!doneN) posN -= offNP * FXAA_QUALITY_P@($i + 2);
                doneNP = (!doneN) || (!doneP);
                if(!doneP) posP += offNP * FXAA_QUALITY_P@($i + 2);
        ]]):reppn("$i", 0, 10))
        @(([[
            }
            #endif
        ]]):reppn("$i", 0, 10))

        float dstN = posM.x - posN.x;
        float dstP = posP.x - posM.x;
        if(!horzSpan) dstN = posM.y - posN.y;
        if(!horzSpan) dstP = posP.y - posM.y;

        bool goodSpanN = (lumaEndN < 0.0) != lumaMLTZero;
        float spanLength = (dstP + dstN);
        bool goodSpanP = (lumaEndP < 0.0) != lumaMLTZero;
        float spanLengthRcp = 1.0/spanLength;

        bool directionN = dstN < dstP;
        float dst = min(dstN, dstP);
        bool goodSpan = directionN ? goodSpanN : goodSpanP;
        float subpixG = subpixF * subpixF;
        float pixelOffset = (dst * (-spanLengthRcp)) + 0.5;
        float subpixH = subpixG * fxaaQualitySubpix;

        float pixelOffsetGood = goodSpan ? pixelOffset : 0.0;
        float pixelOffsetSubpix = max(pixelOffsetGood, subpixH);
        if(!horzSpan) posM.x += pixelOffsetSubpix * lengthSign;
        if( horzSpan) posM.y += pixelOffsetSubpix * lengthSign;

        gl_FragColor = texture2DRect(tex0, posM);
    }
]=]):eval_embedded())