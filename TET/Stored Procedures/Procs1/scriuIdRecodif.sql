--***
create procedure scriuIdRecodif @Id int output, @Tip char(20), @Alfa1 char(20)=null, @Alfa2 char(20)=null, @Alfa3 char(20)=null, 
	@Alfa4 char(20)=null, @Alfa5 char(20)=null, @Alfa6 char(20)=null, @Alfa7 char(20)=null, @Alfa8 char(20)=null, @Alfa9 char(20)=null, @Alfa10 char(20)=null
as

set @Id = dbo.iauIdRecodif(@Tip, @Alfa1, @Alfa2, @Alfa3, @Alfa4, @Alfa5, @Alfa6, @Alfa7, @Alfa8, @Alfa9, @Alfa10)

if @Id > 0
	return

insert recodif
(Tip, Alfa1, Alfa2, Alfa3, Alfa4, Alfa5, Alfa6, Alfa7, Alfa8, Alfa9, Alfa10)
values
(@Tip, isnull(@Alfa1, ''), isnull(@Alfa2, ''), isnull(@Alfa3, ''), isnull(@Alfa4, ''), isnull(@Alfa5, ''), isnull(@Alfa6, ''), isnull(@Alfa7, ''), isnull(@Alfa8, ''), isnull(@Alfa9, ''), isnull(@Alfa10, ''))

set @Id = @@IDENTITY
