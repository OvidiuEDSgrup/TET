USE [TET]
GO
/****** Object:  Trigger [dbo].[DelExtcon]    Script Date: 01/11/2012 17:15:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***
alter trigger [dbo].[|Testcon] on [dbo].[con] for update
as

   RAISERROR
      ('This statement nested over 5 levels of triggers.',16,-1)