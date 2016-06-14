declare @p1 int
set @p1=180150725
declare @p3 int
set @p3=2
declare @p4 int
set @p4=1
declare @p5 int
set @p5=-1
exec sp_cursoropen @p1 output,N'SELECT A.Utilizator,A.Cod,A.Cant_comandata,A.Stoc,A.Cant_aprobata,A.Aprobat_alte,A.Stare,B.Cod,B.Denumire FROM TET..comlivrtmp A, TET..nomencl B WHERE A.Utilizator = @P1  AND B.Cod = A.Cod AND ((0x00=0 or convert(decimal(12,3), A.Cant_comandata-A.Cant_aprobata)>=0.001)) ORDER BY A.Utilizator ASC ,A.Cod ASC ',@p3 output,@p4 output,@p5 output,N'@P1 char(10)','OVIDIU    '
select @p1, @p3, @p4, @p5