/*
 * Copyright (c) 2003-2015, GameDuell GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package vectorx.font;

import lib.ha.core.utils.Debug;
import lib.ha.aggx.typography.FontEngine;
import lib.ha.rfpx.TrueTypeCollection;
import haxe.ds.StringMap;
import types.Data;

@:access(vectorx.font.Font)

class FontCache
{
    var fonts: StringMap<FontEngine> = new StringMap<FontEngine>();
    var defaultFont: String;

    public function new(defaultFont: Data)
    {
        if (defaultFont != null)
        {
            var ttc: TrueTypeCollection = TrueTypeCollection.create(defaultFont);
            var fontEngine: FontEngine = new FontEngine(ttc);
            fonts.set(fontEngine.currentFont.getName(), fontEngine);
            this.defaultFont = fontEngine.currentFont.getName();
            trace('FontCache::new() Loaded default font ${this.defaultFont}');
        }
    }

    public function preloadFontFromTTFData(data: Data)
    {
        trace('FontCache:preloadFontFromTTFData');
        var ttc: TrueTypeCollection = TrueTypeCollection.create(data);
        var fontEngine: FontEngine = new FontEngine(ttc);
        trace('Loaded font: ${fontEngine.currentFont.getName()}');
        fonts.set(fontEngine.currentFont.getName(), fontEngine);
    }

    public function unloadFontWithName(fontName: String): Void
    {
        fonts.set(fontName, null);
    }

    public function createFontWithNameAndSize(fontName: String, sizeInPt: Float): Font
    {
        var fontEngine: FontEngine = fonts.get(fontName);
        if (fontEngine == null)
        {
            fontEngine = fonts.get(defaultFont);
        }

        if (fontEngine == null)
        {
            return null;
        }

        return new Font(fontName, fontEngine, sizeInPt);
    }
}
