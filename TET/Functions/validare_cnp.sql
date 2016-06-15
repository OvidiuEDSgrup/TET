--***
/**	functie validare CNP	*/
create 
function validare_cnp (@cnp char(13)) 
returns char(3)
as
Begin
	Declare @c1 int, @c2 int, @c3 int, @c4 int, @c5 int, @c6 int, @c7 int, @c8 int, @c9 int, @c10 int, 
	@c11 int, @c12 int, @c13 int, @suma int, @Eroare char(3)

	Set @c1 = convert(int,substring(@cnp,1,1))
	Set @c2 = convert(int,substring(@cnp,2,1))
	Set @c3 = convert(int,substring(@cnp,3,1))
	Set @c4 = convert(int,substring(@cnp,4,1))
	Set @c5 = convert(int,substring(@cnp,5,1))
	Set @c6 = convert(int,substring(@cnp,6,1))
	Set @c7 = convert(int,substring(@cnp,7,1))
	Set @c8 = convert(int,substring(@cnp,8,1))
	Set @c9 = convert(int,substring(@cnp,9,1))
	Set @c10 = convert(int,substring(@cnp,10,1))
	Set @c11 = convert(int,substring(@cnp,11,1))
	Set @c12 = convert(int,substring(@cnp,12,1))
	Set @c13 = convert(int,substring(@cnp,13,1))
	Set @suma = @c1*2+@c2*7+@c3*9+@c4+@c5*4+@c6*6+@c7*3+@c8*5+@c9*8+@c10*2+@c11*7+@c12*9
	Set @eroare = (case when left(convert(char(3),@suma % 11),1)<>convert(char(1),@c13) then '1' else '0' end)
	return(@eroare)
end
