--***
create function fStrToken (@String varchar(max), @Index int, @Delimiters varchar(200)) returns varchar(max)
as begin

if @Index <= 0 or @String = ''
	return ''
if @Delimiters = '' and @Index = 1
	return @String
if @Delimiters = ''
	return ''

declare @CrtIndex int, @StrPos int, @NextPos int

select @CrtIndex = 0, @StrPos = 0

while @CrtIndex < @Index - 1 and @StrPos + len(@Delimiters) <= len(@String)
begin
	set @StrPos = charindex(@Delimiters, @String, @StrPos + 1)
	if @StrPos > 0
		select @CrtIndex = @CrtIndex + 1, @StrPos = @StrPos + len(@Delimiters) - 1
	else
		set @StrPos = len(@String)
end

if @CrtIndex < @Index - 1 or @StrPos = len(@String)
	return ''

set @NextPos = charindex(@Delimiters, @String, @StrPos + 1)
if @NextPos = 0
	set @NextPos = len(@String) + 1

return substring(@String, @StrPos + 1, @NextPos - @StrPos - 1)

end
