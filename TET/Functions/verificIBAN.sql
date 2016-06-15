--***
create function verificIBAN (@IBAN char(50), @nLungime int = 0) 
	returns int
as begin 
declare @n97 int, @cifreCtrl char(2), @cifCtrlEronate int, @numarStr char(100), @i int, @car char(1), @restStr char(9), @deimpStr char(9), @nRest int, @nrControl int, @cifCtrlSugerate varchar(2)

set @n97 = 97

set @IBAN = Upper(Replace(Replace(Replace(Replace(@IBAN, ' ', ''), '.', ''), '-', ''), ',', ''))

if @nLungime is null
	set @nLungime = 0
if @nLungime <> 0 and Len(RTrim(@IBAN)) < @nLungime
	return -1
if @nLungime <> 0 and Len(RTrim(@IBAN)) > @nLungime
	return -2

set @cifCtrlEronate = 0
set @cifreCtrl = Substring(@IBAN, 3, 2)
if isnumeric(@cifreCtrl) = 0
begin
	set @cifCtrlEronate = 1
	set @cifreCtrl = '00'
	set @IBAN = left(@IBAN, 2) + @cifreCtrl + Substring(@IBAN, 5, 46)
end

set @IBAN = RTrim(Substring(@IBAN, 5, 46)) + left(@IBAN, 4)

set @numarStr = ''
set @i = 1
while @i <= Len(RTrim(@IBAN))
begin
	set @car = Substring(@IBAN, @i, 1)
	set @numarStr = RTrim(@numarStr) + (case when @car between 'A' and 'Z' then Convert(char(2), ASCII(@car)-55) else @car end)
	set @i = @i + 1
end

set @restStr = ''
set @i = 1
while @i <= Len(RTrim(@numarStr))
begin
	set @deimpStr = RTrim(@restStr) + Substring(@numarStr, @i, 1)
	if isnumeric(@deimpStr) = 0
		return -99
	set @restStr = ltrim(Convert(char(9), Convert(int, @deimpStr) % @n97))
	set @i = @i + 1
end

if isnumeric(@restStr)=0
	return -100

if @cifCtrlEronate = 0 and LTrim(RTrim(@restStr)) = '1'
	return 100

set @nrControl = @n97 + 1-(@n97 + Convert(int, @restStr)-Convert(int, @cifreCtrl)) % @n97
return @nrControl
/*
-- asta daca intorc char; pentru returns int nu are sens...
set @cifCtrlSugerate = Convert(varchar(2), @nrControl)
if Len(@cifCtrlSugerate) = 1
	set @cifCtrlSugerate = '0' + @cifCtrlSugerate

return @cifCtrlSugerate
*/
end
