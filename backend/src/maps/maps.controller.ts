import {
  Controller,
  Get,
  Query,
  ServiceUnavailableException,
  UseGuards,
} from '@nestjs/common';
import {
  IsString,
  MaxLength,
  MinLength,
} from 'class-validator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

class SearchPlacesDto {
  @IsString()
  @MinLength(2)
  @MaxLength(100)
  q!: string;
}

interface GooglePlace {
  id: string;
  displayName?: {
    text?: string;
  };
  formattedAddress?: string;
  location?: {
    latitude: number;
    longitude: number;
  };
  attributions?: {
    provider?: string;
    providerUri?: string;
  }[];
}

@Controller('maps')
@UseGuards(JwtAuthGuard)
export class MapsController {
  @Get('search')
  async search(@Query() query: SearchPlacesDto) {
    const apiKey = process.env.GOOGLE_PLACES_API_KEY;

    if (!apiKey) {
      throw new ServiceUnavailableException(
        'GOOGLE_PLACES_API_KEY is not configured.',
      );
    }

    let response: Response;

    try {
      response = await fetch(
        'https://places.googleapis.com/v1/places:searchText',
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask': [
              'places.id',
              'places.displayName',
              'places.formattedAddress',
              'places.location',
              'places.attributions',
            ].join(','),
          },
          body: JSON.stringify({
            textQuery: query.q.trim(),
            languageCode: 'th',
            regionCode: 'TH',
            pageSize: 10,
          }),
          signal: AbortSignal.timeout(10000),
        },
      );
    } catch {
      throw new ServiceUnavailableException(
        'Unable to connect to Google Places. Please try again.',
      );
    }

    if (!response.ok) {
      throw new ServiceUnavailableException(
        'Search failed. Please check your Google API key, API restrictions, and billing settings.',
      );
    }

    const result = (await response.json()) as {
      places?: GooglePlace[];
    };

    return (result.places ?? [])
      .filter((place) => place.location)
      .map((place) => ({
        googlePlaceId: place.id,
        name: place.displayName?.text ?? 'Unnamed place',
        location: place.formattedAddress ?? '',
        lat: place.location!.latitude,
        lng: place.location!.longitude,
        attributions: place.attributions ?? [],
      }));
  }
}