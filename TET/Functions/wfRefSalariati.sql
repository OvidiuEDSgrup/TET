--***
create function  wfRefSalariati (@Marca char(6)) returns int
as begin
	if exists (select 1 from resal where marca=@Marca)
		return 1
	if exists (select 1 from avexcep where marca=@Marca)
		return 2
	if exists (select 1 from conmed where marca=@Marca)
		return 3
	if exists (select 1 from concodih where marca=@Marca)
		return 4
	if exists (select 1 from pontaj where marca=@Marca)
		return 5
	if exists (select 1 from corectii where marca=@Marca)
		return 6
	if exists (select 1 from persintr where marca=@Marca)
		return 7
	if exists (select 1 from tichete where marca=@Marca)
		return 8
	if exists (select 1 from brut where marca=@Marca)
		return 9
	if exists (select 1 from net where marca=@Marca)
		return 10
	if exists (select 1 from istpers where marca=@Marca)
		return 11
	return 0
end
