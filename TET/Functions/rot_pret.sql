--***
create function rot_pret (@pret float, @suma_rotunjire float) 
returns float
as begin
if isnull(@suma_rotunjire, 0) = 0
	set @suma_rotunjire = isnull((select top 1 suma from rotunj where limita>=@pret order by limita), 0)

declare @pret_out float

if @suma_rotunjire = 0
	set @pret_out = @pret

if @pret_out is null and convert(decimal(18, 5), @pret) % convert(decimal(18, 5), @suma_rotunjire) < @suma_rotunjire / 2
	set @pret_out = @pret - convert(decimal(18, 5), @pret) % convert(decimal(18, 5), @suma_rotunjire)

if @pret_out is null
	set @pret_out = @pret + @suma_rotunjire - convert(decimal(18, 5), @pret) % convert(decimal(18, 5), @suma_rotunjire)

return convert(float, convert(decimal(18, 5), @pret_out))

end
