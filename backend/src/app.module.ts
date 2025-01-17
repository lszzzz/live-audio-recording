import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AudioGateway } from './websocket-gateways/audio/audio.gateway';
import { ConfigModule } from '@nestjs/config';
import { HttpModule } from '@nestjs/axios';

@Module({
  imports: [ConfigModule.forRoot(), HttpModule],
  controllers: [AppController],
  providers: [AppService, AudioGateway],
})
export class AppModule {}
