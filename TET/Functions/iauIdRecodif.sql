--***
create function iauIdRecodif(@Tip char(20), @Alfa1 char(20)=null, @Alfa2 char(20)=null, @Alfa3 char(20)=null, @Alfa4 char(20)=null, 
	@Alfa5 char(20)=null, @Alfa6 char(20)=null, @Alfa7 char(20)=null, @Alfa8 char(20)=null, @Alfa9 char(20)=null, @Alfa10 char(20)=null)
returns int
as begin
	declare @Id int
	
	select @Id=identificator
	from recodif
	where Tip=@Tip 
	and (isnull(@Alfa1, '')='' or Alfa1=@Alfa1) and (isnull(@Alfa2, '')='' or Alfa2=@Alfa2)
	and (isnull(@Alfa3, '')='' or Alfa3=@Alfa3) and (isnull(@Alfa4, '')='' or Alfa4=@Alfa4)
	and (isnull(@Alfa5, '')='' or Alfa5=@Alfa5) and (isnull(@Alfa6, '')='' or Alfa6=@Alfa6)
	and (isnull(@Alfa7, '')='' or Alfa7=@Alfa7) and (isnull(@Alfa8, '')='' or Alfa8=@Alfa8)
	and (isnull(@Alfa9, '')='' or Alfa9=@Alfa9) and (isnull(@Alfa10, '')='' or Alfa10=@Alfa10)
	
	set @Id=isnull(@Id, 0)
	return @Id
end
