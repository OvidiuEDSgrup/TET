--***
/**	functia verifica dreptul */
Create 
function [dbo].[verifica_dreptul] (@user char(30), @user_windows int, @drept char(20))
returns int
As
Begin
	declare @tuser char(30),@tgrupa char(30),@tdrept int,@are_drept int
	if @user_windows=1
		set @tuser=isnull((select max(id) from utilizatori where observatii=@user),'')
	else
		set @tuser=@user
	if @tuser<>''
		set @tgrupa=isnull((select max(id_grup) from gruputiliz where id_utilizator=@tuser),'')
	else
		set @tgrupa=''
	set @tdrept=isnull((select count(drept) from 
	(select tip,id,drept from dreptutiliz where @tuser<>'' and tip='U' and id=@tuser and drept=@drept
	union all
	select tip,id,drept from dreptutiliz where @tgrupa<>'' and tip='G' and id=@tgrupa and drept=@drept) a),0)
	set @are_drept=0
	if @tdrept>0
		set @are_drept=1
	else
		set @are_drept=0

	return @are_drept
End
