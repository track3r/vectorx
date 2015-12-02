package vectorx.font;

import types.Vector2;
import types.Color4F;
import vectorx.font.AttributedString.StringAttributes;
import types.Range;

class AttributedSpan
{
    public var range(default, null): AttributedRange;
    public var font: Font = null;
    public var backgroundColor: Color4F = null;
    public var foregroundColor: Color4F = null;
    public var baselineOffset:  Null<Float>;
    public var kern: Null<Float> = null;
    public var strokeWidth: Null<Float> = null;
    public var strokeColor: Color4F = null;
    public var shadow: FontShadow = null;
    public var attachment: FontAttachment = null;

    public var baseString(default, null): String;
    public var string(default, null): String;

    private var measure: Vector2 = new Vector2();
    private var measured: Bool = false;

    private var id(default, null): Int;
    private static var nextId: Int = 0;

    public function new(range: AttributedRange, string: String)
    {
        this.range = range;
        id = nextId++;

        baseString = string;
        updateString();
    }

    public function updateString()
    {
        this.string = baseString.substr(range.index, range.length);
    }

    public function toString(): String
    {
        return '{id: $id, range: ${range.index}[${range.length}] str: $string font: $font bgColor: $backgroundColor fgColor: $foregroundColor}';
    }

    private inline function choose<T>(dst: T, src: T)
    {
        if (src == null)
        {
            return dst;
        }

        return src;
    }

    public function apply(source: AttributedSpan)
    {
        font = choose(font, source.font);
        backgroundColor = choose(backgroundColor, source.backgroundColor);
        foregroundColor = choose(foregroundColor, source.foregroundColor);
        baselineOffset = choose(baselineOffset, source.baselineOffset);
        kern = choose(kern, source.kern);
        strokeWidth = choose(strokeWidth, source.strokeWidth);
        strokeColor = choose(strokeColor, source.strokeColor);
        shadow = choose(shadow, source.shadow);
        attachment = choose(attachment, source.attachment);
        measured = false;
    }

    public function applyAttributes(source: StringAttributes)
    {
        font = choose(font, source.font);
        backgroundColor = choose(backgroundColor, source.backgroundColor);
        foregroundColor = choose(foregroundColor, source.foregroundColor);
        baselineOffset = choose(baselineOffset, source.baselineOffset);
        kern = choose(kern, source.kern);
        strokeWidth = choose(strokeWidth, source.strokeWidth);
        strokeColor = choose(strokeColor, source.strokeColor);
        shadow = choose(shadow, source.shadow);
        attachment = choose(attachment, source.attachment);
        measured = false;
    }

    public function getMeasure(): Vector2
    {
        if (!measured)
        {
            font.internalFont.measureString(string, font.sizeInPt, measure);
            measured = true;
        }

        return measure;
    }
}
