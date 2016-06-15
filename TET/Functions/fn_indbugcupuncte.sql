create function [dbo].[fn_indbugcupuncte] (@indbug varchar(40))
returns varchar(40)
as begin
	return(isnull(substring(rtrim(ltrim(@indbug)),1,2),'')+
	(case when isnull(substring(rtrim(ltrim(@indbug)),3,2),'')<>'' then '.' else ''end)+isnull(substring(rtrim(ltrim(@indbug)),3,2),'')+
	(case when isnull(substring(rtrim(ltrim(@indbug)),5,2),'')<>'' then '.' else ''end)+isnull(substring(rtrim(ltrim(@indbug)),5,2),'')+
	(case when isnull(substring(rtrim(ltrim(@indbug)),7,2),'')<>'' then '.' else ''end)+isnull(substring(rtrim(ltrim(@indbug)),7,2),'')+
	(case when isnull(substring(rtrim(ltrim(@indbug)),9,2),'')<>'' then '.' else ''end)+isnull(substring(rtrim(ltrim(@indbug)),9,2),'')+
	(case when isnull(substring(rtrim(ltrim(@indbug)),11,2),'')<>'' then '.' else ''end)+isnull(substring(rtrim(ltrim(@indbug)),11,2),'')+
	(case when isnull(substring(rtrim(ltrim(@indbug)),13,2),'')<>'' then '.' else ''end)+isnull(substring(ltrim(rtrim(@indbug)),13,2),'')+
	(case when isnull(substring(rtrim(ltrim(@indbug)),15,2),'')<>'' then '.' else ''end)+isnull(substring(ltrim(rtrim(@indbug)),15,2),''))
end
