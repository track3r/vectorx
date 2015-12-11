package vectorx.font;

import lib.ha.core.utils.Debug;
import lib.ha.aggx.typography.FontEngine;
import haxe.Utf8;

class TextLine
{
    public var begin(default, null): Int;
    public var lenght(get, null): Int;
    public var width(default, null): Float = 0;
    public var maxSpanHeight(default, null): Float = 0;
    public var maxBgHeight(default, null): Float = 0;

    public var spans: Array<AttributedSpan> = [];

    private var breakAt: Int = -1;
    private var charAtBreakPos: Int = 0;

    private static inline var SPACE = 32;
    private static inline var TAB = 9;
    private static inline var NEWLINE = 10;

    public function toString(): String
    {
        var str: StringBuf = new StringBuf();
        str.add('{begin: $begin breakAt: $breakAt len: $lenght width: $width spans:\n {');
        for (span in spans)
        {
            str.add('{$span}\n');
        }
        str.add("}");
        return str.toString();
    }

    private function new(begin: Int = 0)
    {
        this.begin = begin;
    }

    public function get_lenght(): Int
    {
        if (breakAt == -1)
        {
            return -1;
        }

        return breakAt - begin;
    }

    private function calculateMaxSpanHeight(span: AttributedSpan)
    {
        var fontEngine: FontEngine = span.font.internalFont;
        var spanString: String = span.string;
        var measure = span.getMeasure();

        if (measure.y > maxSpanHeight)
        {
            maxSpanHeight = measure.y;
        }
    }

    private function calculateMaxBgHeight(span: AttributedSpan)
    {
        var fontEngine: FontEngine = span.font.internalFont;
        var spanString: String = span.string;
        var measure = span.getMeasure();
        var alignY: Float = maxSpanHeight - measure.y;

        for (i in 0 ... Utf8.length(spanString))
        {
            var face = fontEngine.getFace(Utf8.charCodeAt(spanString, i));
            if (face.glyph.bounds == null)
            {
                continue;
            }
            var scale = fontEngine.getScale(span.font.sizeInPt);

            var by =  -face.glyph.bounds.y1 * scale;
            var h = (-face.glyph.bounds.y2 - -face.glyph.bounds.y1) * scale;

            var ext: Float = (alignY + measure.y + by);
            if (ext > maxBgHeight)
            {
                maxBgHeight = ext;
            }
        }
    }

    private static var currentWidth: Float = 0;
    private static var textWidth: Float = 0;
    private static var pos: Int = 0;
    private static var currentLine: TextLine = null;

    public static function calculate(string: AttributedString, width: Float, pixelRatio: Float = 1.0): Array<TextLine>
    {
        var output: Array<TextLine> = [];

        currentWidth = 0;
        pos = 0;
        textWidth = width;

        currentLine = new TextLine();
        output.push(currentLine);

        var spanIterator = string.attributeStorage.iterator();
        while (spanIterator.hasNext())
        {
            var span: AttributedSpan = spanIterator.next();
            currentLine.spans.push(span);
            trace(span);

            var fontEngine: FontEngine = span.font.internalFont;
            var spanString: String = span.string;
            var scale = fontEngine.getScale(span.font.sizeInPt) * pixelRatio;
            var kern = span.kern == null ? 0 : span.kern;
            kern *= pixelRatio;

            for (i in 0 ... Utf8.length(spanString))
            {
                var advance: Float = 0;
                var needNewLine: Bool = false;
                var code: Int = Utf8.charCodeAt(spanString, i);

                if (code == NEWLINE)
                {
                    var force: Bool = true;
                    span = newLine(code, output, 0, force);
                }
                else
                {
                    if (code == SPACE || code == TAB)
                    {
                        //trace('space: $pos');
                        currentLine.breakAt = pos;
                        currentLine.charAtBreakPos = code;
                        currentLine.width = currentWidth;
                    }

                    var face = fontEngine.getFace(code);
                    advance = face.glyph.advanceWidth * scale + kern;
                    trace('+${Utf8.sub(spanString, i, 1)} advance $advance = ${currentWidth + advance} pos: $pos');
                }

                span = newLine(code, output, advance);
                pos++;
            }

            if (span.attachment != null)
            {
                var code: Int = 0x1F601;
                var advance: Float = span.attachment.bounds.width + kern + 2;
                trace('+attachment advance $advance = ${currentWidth + advance}');
                span = newLine(code, output, advance);
            }
        }

        output[output.length - 1].breakAt = -1;
        output[output.length - 1].width = currentWidth;

        for(line in output)
        {
            string.attributeStorage.eachSpanInRange(function(span: AttributedSpan)
            {
                line.calculateMaxSpanHeight(span);
            }, line.begin, line.lenght);

            string.attributeStorage.eachSpanInRange(function(span: AttributedSpan)
            {
                line.calculateMaxBgHeight(span);
            }, line.begin, line.lenght);

            line.maxSpanHeight *= pixelRatio;
            line.maxBgHeight *= pixelRatio;
        }

        return output;
    }

    private static function newLine(code: Int, output: Array<TextLine>, advance: Float, force: Bool = false): AttributedSpan
    {
        var currentSpan = currentLine.spans[currentLine.spans.length - 1];

        if (currentWidth + advance > textWidth || force)
        {

            if (currentLine.breakAt == -1)
            {
                currentLine.breakAt = pos;
                currentLine.charAtBreakPos = code;
                currentLine.width = currentWidth;
            }
            currentWidth -= currentLine.width;

            var startAt: Int = currentLine.breakAt;
            switch (currentLine.charAtBreakPos)
            {
                case SPACE | TAB | NEWLINE: startAt++;
                default:
            }

            var rightBound = currentSpan.range.index + currentSpan.range.length;
            trace('rightBound: $rightBound startAt: $startAt');
            if (rightBound >= startAt || (rightBound == startAt && currentSpan.attachment != null))
            {
                currentLine.spans.pop();
                var leftSpan: AttributedSpan = new AttributedSpan("");
                leftSpan.setFromSpan(currentSpan);
                leftSpan.attachment = null;
                leftSpan.range.length = startAt - leftSpan.range.index;
                leftSpan.updateString();

                var rightSpan: AttributedSpan = new AttributedSpan("");
                rightSpan.setFromSpan(currentSpan);
                rightSpan.range.index = startAt;
                rightSpan.range.length = currentSpan.range.length - leftSpan.range.length;
                rightSpan.updateString();

                currentSpan = rightSpan;
            }
            trace(currentLine);
            currentLine = new TextLine(startAt);
            output.push(currentLine);
        }

        currentWidth += advance;
        return currentSpan;
    }
}
